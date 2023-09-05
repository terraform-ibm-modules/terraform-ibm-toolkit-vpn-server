
locals {
  prefix_name = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  name        = lower(replace("${local.prefix_name}-vpn-${var.resource_label}", "_", "-"))
  vpn_profile = "${path.root}/${local.name}.ovpn"
  sm_region   = var.sm_region != "" ? var.sm_region : var.region
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

module "clis" {
  source = "cloud-native-toolkit/clis/util"

  clis = ["ibmcloud-is"]
}

resource "null_resource" "print_resources" {
  provisioner "local-exec" {
    command = "echo 'Resource group: ${var.resource_group_name}'"
  }
}

data "ibm_resource_group" "resource_group" {
  depends_on = [null_resource.print_resources]

  name = var.resource_group_name
}

# Generate the Server and Client certificates
resource "null_resource" "create_certificates" {
  provisioner "local-exec" {
    command     = "${path.module}/scripts/create-certificates.sh"
    working_dir = path.root
    environment = {
      BIN_DIR = module.clis.bin_dir
    }
  }
}

data "local_file" "ca" {
  depends_on = [
    null_resource.create_certificates
  ]
  filename = "${path.root}/certificates/ca.crt"
}

data "local_file" "server_cert" {
  depends_on = [
    null_resource.create_certificates
  ]
  filename = "${path.root}/certificates/issued/vpn-server.vpn.ibm.com.crt"
}

data "local_file" "server_key" {
  depends_on = [
    null_resource.create_certificates
  ]
  filename = "${path.root}/certificates/private/vpn-server.vpn.ibm.com.key"
}

data "local_file" "client_cert" {
  depends_on = [
    null_resource.create_certificates
  ]
  filename = "${path.root}/certificates/issued/client1.vpn.ibm.com.crt"
}

data "local_file" "client_key" {
  depends_on = [
    null_resource.create_certificates
  ]
  filename = "${path.root}/certificates/private/client1.vpn.ibm.com.key"
}

# Create group in Security Manager for VPN certificates
locals {
  sm_group_name = "vpn-cert-group-${random_string.suffix.result}"
}


resource "ibm_sm_secret_group" "sm_secret_group" {
  instance_id = var.secrets_manager_guid
  region      = local.sm_region
  name        = local.sm_group_name
  description = "VPN Certificates Group"
}

# Import certificates to security manager group
locals {
  server-secret-name = "vpn-server-cert-${random_string.suffix.result}"
  client-secret-name = "vpn-client-cert-${random_string.suffix.result}"
}

resource "ibm_sm_imported_certificate" "server_cert_secret" {
  instance_id     = var.secrets_manager_guid
  region          = local.sm_region
  name            = local.server-secret-name
  description     = "VPN server certificate"
  labels          = [local.name]
  secret_group_id = ibm_sm_secret_group.sm_secret_group.secret_group_id
  certificate     = data.local_file.server_cert.content
  intermediate    = data.local_file.ca.content
  private_key     = data.local_file.server_key.content
}


resource "ibm_sm_imported_certificate" "client_cert_secret" {
  instance_id     = var.secrets_manager_guid
  region          = local.sm_region
  name            = local.client-secret-name
  description     = "VPN client certificate"
  labels          = [local.name]
  secret_group_id = ibm_sm_secret_group.sm_secret_group.secret_group_id
  certificate     = data.local_file.client_cert.content
  intermediate    = data.local_file.ca.content
  private_key     = data.local_file.client_key.content
}

# Update the subnet Access Control List that will be used for the VPN server
resource "null_resource" "update_rules" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/update-rules.sh"
    environment = {
      IBMCLOUD_API_KEY = var.ibmcloud_api_key
      SUBNET_ID        = var.subnet_ids[0]
      REGION           = var.region
      RESOURCE_GROUP   = data.ibm_resource_group.resource_group.id
      BIN_DIR          = module.clis.bin_dir
    }
  }
}

# Create a Security Group for the VPN Server
resource "ibm_is_security_group" "vpn_security_group" {
  name           = "${local.name}-group"
  vpc            = var.vpc_id
  resource_group = data.ibm_resource_group.resource_group.id
}

resource "ibm_is_security_group_rule" "inbound" {
  group     = ibm_is_security_group.vpn_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
}

resource "ibm_is_security_group_rule" "outbound" {
  group     = ibm_is_security_group.vpn_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}



resource "ibm_is_vpn_server" "vpn_server" {
  resource_group  = data.ibm_resource_group.resource_group.id
  name            = local.name
  subnets         = slice(var.subnet_ids, 0, min(2, length(var.subnet_ids)))
  certificate_crn = ibm_sm_imported_certificate.server_cert_secret.crn
  client_authentication {
    method        = var.auth_method
    client_ca_crn = ibm_sm_imported_certificate.client_cert_secret.crn
  }
  client_ip_pool         = var.vpnclient_ip
  enable_split_tunneling = var.enable_split_tunnel
  port                   = var.vpn_server_port
  protocol               = var.vpn_server_proto
  security_groups        = [ibm_is_security_group.vpn_security_group.id]
  client_dns_server_ips  = var.client_dns
  client_idle_timeout    = var.vpn_client_timeout
}


resource "ibm_is_vpn_server_route" "vpc-network" {
  vpn_server  = ibm_is_vpn_server.vpn_server.id
  destination = var.vpc_cidr
  name        = "vpc-network"
}

resource "ibm_is_vpn_server_route" "services" {
  vpn_server  = ibm_is_vpn_server.vpn_server.id
  destination = var.services_cidr
  name        = "services"
}

resource "ibm_is_vpn_server_route" "dns" {
  vpn_server  = ibm_is_vpn_server.vpn_server.id
  destination = var.dns_cidr
  name        = "dns"
}

# Download the client profile & inject certificates
resource "null_resource" "client_profile" {
  depends_on = [
    ibm_is_vpn_server.vpn_server
  ]

  provisioner "local-exec" {
    command     = "${path.module}/scripts/generate-profile.sh"
    working_dir = path.root
    environment = {
      BIN_DIR          = module.clis.bin_dir
      IBMCLOUD_API_KEY = var.ibmcloud_api_key
      REGION           = var.region
      RESOURCE_GROUP   = var.resource_group_name
      VPN_SERVER       = local.name
    }
  }
}
