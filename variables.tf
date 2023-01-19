variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api key"
}

variable "region" {
  type        = string
  description = "The IBM Cloud region where the resources will be provisioned."
}

variable "sm_region" {
  type        = string
  description = "The IBM Cloud region where the Service Manager resides if different from VPC and VPN server"
  default     = ""
}

variable "resource_label" {                   
  type        = string                        
  description = "The label for the resource to which the vpe will be connected. Used as a tag and as part of the vpe name."
  default     = "vpn"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the IBM Cloud resource group where the resources will be provisioned."
}

variable "secrets_manager_guid" {
  type        = string
  description = "The secrets manager instance guid."
}

variable "vpc_id" {
  type        = string
  description = "The id of the vpc instance."
}

variable "subnet_ids" {
  type        = list(string)
  description = "The array of ids (strings) for the subnet that the VPN will be connected to."
}

variable "name_prefix" {
  type        = string
  description = "The name of the vpn resource"
  default     = ""
}

variable "vpnclient_ip" {
  type        = string
  description = "VPN Client IP Range"
  default     = "172.16.0.0/16"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR for the private VPC the VPN is connected to."
  default     = "10.0.0.0/8"
}

variable "dns_cidr" {
  type = string
  description = "CIDR for the DNS servers in the private VPC the VPN is connected to."
  default = "161.26.0.0/16"
}

variable "services_cidr" {
  type = string
  description = "CIDR for the services in the private VPC the VPN is connected to."
  default = "166.8.0.0/14"
}

variable "client_dns" {
  type        = list(string)
  description = "Comma-separated DNS IPs for VPN Client Use ['161.26.0.10','161.26.0.11'] for public endpoints, or ['161.26.0.7','161.26.0.8'] for private endpoints"
  default     =  ["161.26.0.7","161.26.0.8"]
}

variable "auth_method" {
  type        = string
  description = "VPN Client Auth Method. One of: certificate, username, certificate,username, username,certificate"
  default     =  "certificate"
}

variable "vpn_server_proto" {
  type        = string
  description = "VPN Server Protocol. One of: udp or tcp"
  default     = "udp"
}

variable "vpn_server_port" {
  type        = number
  description = "VPN Server Port number"
  default     = 443
}

variable "vpn_client_timeout" {
  type        = number
  description = "VPN Server Client Time out"
  default     =  600
}

variable "enable_split_tunnel" {
  type        = bool
  description = "VPN server Tunnel Type"
  default     = true
}
