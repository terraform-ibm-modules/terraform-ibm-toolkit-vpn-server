terraform {
  required_version = ">= 0.13.0"
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "~> 1.35.0"
    }
  }
}


provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

module "resource_group" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-resource-group.git"

  resource_group_name = var.resource_group_name
  provision           = false
}