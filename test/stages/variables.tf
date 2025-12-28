
# Resource Group Variables
variable "resource_group_name" {
  type        = string
  description = "Existing resource group where vpn server will be provisioned"
}

variable "ibmcloud_api_key" {
  type        = string
  description = "The api key for IBM Cloud access"
}

variable "region" {
  type        = string
  description = "Region for VPC infrastructure services resources."
}

variable "sm_region" {
  type        = string
  description = "Region for secrets manager"
  default     = ""
}

variable "sm_guid" {
  type        = string
  description = "Secrets manager service instance GUID"
  default     = ""
}


variable "name_prefix" {
  type        = string
  description = "Prefix name that should be used for the cluster and services. If not provided then resource_group_name will be used"
  default     = "vpn-test"
}
