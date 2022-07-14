
locals {
  prefix_name     = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  name            = lower(replace("${local.prefix_name}-vpn-${var.resource_label}", "_", "-"))
  vpn_profile     = "${path.root}/${local.name}.ovpn"
}

module "clis" {
  source = "cloud-native-toolkit/clis/util"

  clis = ["ibmcloud-is"]
}

resource null_resource print_resources {
  provisioner "local-exec" {
    command = "echo 'Resource group: ${var.resource_group_name}'"
  }
}

data "ibm_resource_group" "resource_group" {
  depends_on = [null_resource.print_resources]

  name = var.resource_group_name
}

# Generate the Server and Client certificates and import them into the Certificate Manager instance
resource null_resource create_certificates {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-certificates.sh"
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

resource "ibm_certificate_manager_import" "server_cert" {
  certificate_manager_instance_id = var.certificate_manager_id
  name                            = "vpn-server-cert"
  description                     = "VPN server certificate"
  data = {
    content = data.local_file.server_cert.content
    intermediate = data.local_file.ca.content
    priv_key = data.local_file.server_key.content
  }
}

resource "ibm_certificate_manager_import" "client_cert" {
  certificate_manager_instance_id = var.certificate_manager_id
  name                            = "vpn-client-cert"
  description                     = "VPN client certificate"
  data = {
    content = data.local_file.client_cert.content
    intermediate = data.local_file.ca.content
    priv_key = data.local_file.client_key.content
  }
}

# Update the subnet Access Control List that will be used for the VPN server
resource null_resource update_rules {
   provisioner "local-exec" {
       command = "${path.module}/scripts/update-rules.sh"
       environment = {
           IBMCLOUD_API_KEY = var.ibmcloud_api_key
           SUBNET_ID = var.subnet_ids[0]
           REGION = var.region
           RESOURCE_GROUP = data.ibm_resource_group.resource_group.id
           BIN_DIR = module.clis.bin_dir
       }
   }
 }

# Create a Security Group for the VPN Server
resource ibm_is_security_group vpn_security_group {
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


# Provision the VPN Server instance & create the VPN Server Routes 
resource null_resource vpn_server {
  depends_on = [
    ibm_certificate_manager_import.server_cert,
    ibm_is_security_group.vpn_security_group,
    ibm_is_security_group_rule.inbound,
    ibm_is_security_group_rule.outbound,
    null_resource.update_rules
  ]

  triggers = {
    IBMCLOUD_API_KEY = base64encode(var.ibmcloud_api_key)
    REGION = var.region
    RESOURCE_GROUP =  var.resource_group_name
    VPN_SERVER = local.name
    BIN_DIR = module.clis.bin_dir
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-vpn.sh"
    working_dir = path.root

    environment = {
      IBMCLOUD_API_KEY = var.ibmcloud_api_key
      REGION  =  var.region
      RESOURCE_GROUP  =  var.resource_group_name
      VPN_SERVER  =  local.name
      SUBNET_IDS  =  join(",", slice(var.subnet_ids, 0, min(2,length(var.subnet_ids))))
      SERVER_CERT_CRN  =  ibm_certificate_manager_import.server_cert.id
      CLIENT_CERT_CRN  =  ibm_certificate_manager_import.client_cert.id
      VPNCLIENT_IP  =  var.vpnclient_ip
      CLIENT_DNS  =  join(",", var.client_dns)
      AUTH_METHOD =  var.auth_method
      SECGRP_ID  =  ibm_is_security_group.vpn_security_group.id
      VPN_PROTO  = var.vpn_server_proto
      VPN_PORT   = var.vpn_server_port
      SPLIT_TUNNEL = var.enable_split_tunnel
      IDLE_TIMEOUT  = var.vpn_client_timeout
      BIN_DIR = self.triggers.BIN_DIR
    }
  }

  # Delete on_destroy
  provisioner "local-exec" {
    when    = destroy
    command = "${path.module}/scripts/delete-vpn.sh"

    environment = {
      IBMCLOUD_API_KEY = base64decode(self.triggers.IBMCLOUD_API_KEY)
      REGION  =  self.triggers.REGION
      RESOURCE_GROUP  =  self.triggers.RESOURCE_GROUP
      VPN_SERVER  =  self.triggers.VPN_SERVER
      BIN_DIR = self.triggers.BIN_DIR
    }
  }
}

# Download the client profile & inject certificates
resource null_resource client_profile {   
  depends_on = [
    null_resource.vpn_server
  ]

  provisioner "local-exec" {
    command = "${path.module}/scripts/generate-profile.sh"
    working_dir = path.root
    environment = {
      BIN_DIR = module.clis.bin_dir
      IBMCLOUD_API_KEY = var.ibmcloud_api_key
      REGION  =  var.region
      RESOURCE_GROUP  =  var.resource_group_name
      VPN_SERVER = local.name
    }
  }
}
