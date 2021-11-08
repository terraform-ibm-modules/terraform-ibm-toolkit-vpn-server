module "vpc" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc.git"

  resource_group_id   = module.resource_group.id
  resource_group_name = module.resource_group.name
  name_prefix         = var.name_prefix
}

module "gateways" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc-gateways.git"

  resource_group_id = module.resource_group.id
  vpc_name          = module.vpc.name
  subnet_count      = 2
}

module "subnets" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-vpc-subnets.git"

  resource_group_id = module.resource_group.id
  vpc_name          = module.vpc.name
  gateways          = module.gateways.gateways
  _count            = 2
}