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
