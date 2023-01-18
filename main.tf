
locals {
  prefix_name     = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  name            = lower(replace("${local.prefix_name}-vpn-${var.resource_label}", "_", "-"))
  vpn_profile     = "${path.root}/${local.name}.ovpn"
}

resource "random_string" "suffix" {
  length           = 8
  special          = false
  upper            = false
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

# Generate the Server and Client certificates
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

# Create group in Security Manager for VPN certificates
locals {
  sm_group_name = "vpn-cert-group-${random_string.suffix.result}"
}

resource "null_resource" "security_group" {

    triggers = {
      ibmcloud_api_key = var.ibmcloud_api_key
      bin_dir          = module.clis.bin_dir
      name             = local.sm_group_name
      description      = "VPN Certificates Group"
      region           = var.region
      instance_id      = var.secrets_manager_guid
    }

    provisioner "local-exec" {
        command = "${path.module}/scripts/create-group.sh"

        environment = {
          IBMCLOUD_API_KEY  = self.triggers.ibmcloud_api_key
          BIN_DIR           = self.triggers.bin_dir
          NAME              = self.triggers.name
          DESCRIPTION       = self.triggers.description
          REGION            = self.triggers.region
          INSTANCE_ID       = self.triggers.instance_id
        }
    }

    provisioner "local-exec" {
        when = destroy

        command = "${path.module}/scripts/delete-group.sh"

        environment = {
          IBMCLOUD_API_KEY  = self.triggers.ibmcloud_api_key
          REGION            = self.triggers.region
          BIN_DIR           = self.triggers.bin_dir
          INSTANCE_ID       = self.triggers.instance_id
          NAME              = self.triggers.name
         }
    }

}

data "external" "sm_group" {
  depends_on = [null_resource.security_group]

  program = ["bash", "${path.module}/scripts/get-group-id.sh"]

  query = {
    ibmcloud_api_key    = var.ibmcloud_api_key
    bin_dir             = module.clis.bin_dir
    group_name          = local.sm_group_name
    region              = var.region   
    instance_id         = var.secrets_manager_guid
  }
}

# Import certificates to security manager group
locals {
  server-secret-name = "vpn-server-cert-${random_string.suffix.result}"
  client-secret-name = "vpn-client-cert-${random_string.suffix.result}"
}
resource "null_resource" "server_cert_secret" {

    triggers = {
        ibmcloud_api_key = var.ibmcloud_api_key
        bin_dir          = module.clis.bin_dir
        name             = local.server-secret-name
        description      = "VPN server certificate"
        region           = var.region
        instance_id      = var.secrets_manager_guid
        group_id         = data.external.sm_group.result.group_id
        labels           = local.name
        certificate      = replace("${data.local_file.server_cert.content}", "\n", "\\n")
        private_key      = replace("${data.local_file.server_key.content}", "\n", "\\n")
        intermediate     = replace("${data.local_file.ca.content}", "\n", "\\n")
    }

    provisioner "local-exec" {
        command = "${path.module}/scripts/import-certificate.sh"

        environment = {
            IBMCLOUD_API_KEY  = self.triggers.ibmcloud_api_key
            BIN_DIR           = self.triggers.bin_dir
            NAME              = self.triggers.name
            DESCRIPTION       = self.triggers.description
            REGION            = self.triggers.region
            INSTANCE_ID       = self.triggers.instance_id
            GROUP_ID          = self.triggers.group_id
            LABELS            = self.triggers.labels
            CERT              = self.triggers.certificate
            PRIV_KEY          = self.triggers.private_key
            CA_CERT           = self.triggers.intermediate
        }
    }

    provisioner "local-exec" {
        when = destroy
        command = "${path.module}/scripts/delete-secret.sh"

        environment = {
            IBMCLOUD_API_KEY  = self.triggers.ibmcloud_api_key
            BIN_DIR           = self.triggers.bin_dir
            NAME              = self.triggers.name
            REGION            = self.triggers.region
            INSTANCE_ID       = self.triggers.instance_id
            GROUP_ID          = self.triggers.group_id
            TYPE              = "imported_cert"
        }
    }
}

data "external" "server-secret" {
  depends_on = [null_resource.server_cert_secret]

  program = ["bash", "${path.module}/scripts/get-secret-id.sh"]

  query = {
    ibmcloud_api_key    = var.ibmcloud_api_key
    bin_dir             = module.clis.bin_dir
    group_id            = data.external.sm_group.result.group_id
    region              = var.region   
    instance_id         = var.secrets_manager_guid
    name                = local.server-secret-name
  }  
}

resource "null_resource" "client_cert_secret" {

    triggers = {
        ibmcloud_api_key = var.ibmcloud_api_key
        bin_dir          = module.clis.bin_dir
        name             = local.client-secret-name
        description      = "VPN client certificate"
        region           = var.region
        instance_id      = var.secrets_manager_guid
        group_id         = data.external.sm_group.result.group_id
        labels           = local.name
        certificate      = replace("${data.local_file.client_cert.content}", "\n", "\\n")
        private_key      = replace("${data.local_file.client_key.content}", "\n", "\\n")
        intermediate     = replace("${data.local_file.ca.content}", "\n", "\\n")
    }

    provisioner "local-exec" {
        command = "${path.module}/scripts/import-certificate.sh"

        environment = {
            IBMCLOUD_API_KEY  = self.triggers.ibmcloud_api_key
            BIN_DIR           = self.triggers.bin_dir
            NAME              = self.triggers.name
            DESCRIPTION       = self.triggers.description
            REGION            = self.triggers.region
            INSTANCE_ID       = self.triggers.instance_id
            GROUP_ID          = self.triggers.group_id
            LABELS            = self.triggers.labels
            CERT              = self.triggers.certificate
            PRIV_KEY          = self.triggers.private_key
            CA_CERT           = self.triggers.intermediate
        }
    }

    provisioner "local-exec" {
        when = destroy
        command = "${path.module}/scripts/delete-secret.sh"

        environment = {
            IBMCLOUD_API_KEY  = self.triggers.ibmcloud_api_key
            BIN_DIR           = self.triggers.bin_dir
            NAME              = self.triggers.name
            REGION            = self.triggers.region
            INSTANCE_ID       = self.triggers.instance_id
            GROUP_ID          = self.triggers.group_id
            TYPE              = "imported_cert"
        }
    }
}

data "external" "client-secret" {
  depends_on = [null_resource.client_cert_secret]

  program = ["bash", "${path.module}/scripts/get-secret-id.sh"]

  query = {
    ibmcloud_api_key    = var.ibmcloud_api_key
    bin_dir             = module.clis.bin_dir
    group_id            = data.external.sm_group.result.group_id
    region              = var.region   
    instance_id         = var.secrets_manager_guid
    name                = local.client-secret-name
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
      SERVER_CERT_CRN  =  data.external.server-secret.result.crn
      CLIENT_CERT_CRN  =  data.external.client-secret.result.crn
      VPNCLIENT_IP  =  var.vpnclient_ip
      VPC_CIDR = var.vpc_cidr
      DNS_CIDR = var.dns_cidr
      SERVICES_CIDR = var.services_cidr
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
