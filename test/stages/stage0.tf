terraform {
  required_version = ">= 0.13.0"
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = ">= 1.35.0"
    }
  }
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"

  bin_dir = "${path.cwd}/test_bin_dir"
  clis = ["ibmcloud-is"]
}

resource local_file bin_dir {
  filename = "${path.cwd}/.bin_dir"

  content = module.setup_clis.bin_dir
}
