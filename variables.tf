variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api key"
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the resources will be provisioned."
}

variable "resource_label" {                   
  type        = string                        
  description = "The label for the resource to which the vpe will be connected. Used as a tag and as part of the vpe name."
}

# variable "resource_group_id" {
#   type        = string
#   description = "The id of the IBM Cloud resource group where the resources will be provisioned."
# }

variable "resource_group_name" {
  type        = string
  description = "The name of the IBM Cloud resource group where the resources will be provisioned."
}


variable "certificate_manager_instance_name" {
  type        = string
  description = "The certificate manager instance name."
}


variable "vpc_id" {
  type        = string
  description = "The id for the VPC that the VPN will be connected to."
}

variable "subnet_id" {
  type        = string
  description = "The id for the subnet that the VPN will be connected to."
}









variable "name_prefix" {
  type        = string
  description = "The name of the vpc resource"
  default     = ""
}


# variable "vpn_server_name" {
#   type        = string
#   description = "The IBM Cloud VPN Server name."
#   default  =  "testvpn22"
# }

# variable "vpc_id" {
#   type        = string
#   description = "The id of the vpc instance"
#   default  =  "r014-26df69c9-e749-478a-b7ac-cb4e67fa89b3"
# }





variable "vpnclient_ip" {
  type        = string
  description = "VPN Client IP Range"
  default = "172.16.0.0/16"
}

variable "client_dns" {
  type        = string
  description = "DNS for VPN Client"
  default  =  "161.26.0.7"
}

variable "auth_method" {
  type        = string
  description = "VPN Client Auth Method"
  default  =  "certificate"
}

# variable "secgrp_id" {
#   type        = string
#   description = "Security Group ID for VPN Server"
#   default  =  "r014-5f7b0a7e-de12-49cb-8d5d-4e5b9c133bd2"
# }

variable "vpn_server_proto" {
  type        = string
  description = "VPN Server Protocol"
  default  =  "udp"
}

variable "vpn_server_port" {
  type        = number
  description = "VPN Server Port number"
  default  =  "443"
}

variable "vpn_client_timeout" {
  type        = number
  description = "VPN Server Client Time out"
  default  =  "600"
}


variable "enable_split_tunnel" {
  type        = string
  description = "VPN server Tunnel Type"
  default  =  "true"
}


# variable "sync" {                                                                                                               
#   type        = string                                                                                                          
#   description = "Value used to synchronize dependencies between modules"                                                        
#   default     = ""                                                                                                              
# }      

# variable "vpn_server_id" {
#   type        = string
#   description = "Value used to synchronize dependencies between modules"
#   default     = ""
# }


# variable "vpn_route_name" {
#   type        = string
#   description = "Value used to synchronize dependencies between modules"
#   default     = ""
# }

# variable "route_cidr" {
#   type        = string
#   description = "Value used to synchronize dependencies between modules"
#   default     = ""
# }
