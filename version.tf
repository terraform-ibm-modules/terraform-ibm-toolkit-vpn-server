terraform {
  required_version = ">= 0.13.0"
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "~> 1.35.0"
    }
  }
}
