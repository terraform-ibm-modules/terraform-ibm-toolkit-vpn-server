module "vpc" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc.git"

  resource_group_name = module.resource_group.name
  region              = var.region
  name_prefix         = var.name_prefix
}
