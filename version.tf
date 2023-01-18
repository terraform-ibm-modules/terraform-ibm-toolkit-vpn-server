terraform {
  required_version = ">= 0.13.0"

  required_providers {
    ibm = {
      source = "ibm-cloud/ibm"
      version = ">= 1.22.0"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3.4.0"
    }
  }
}
