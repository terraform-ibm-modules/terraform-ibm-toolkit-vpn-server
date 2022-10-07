
module "vpn_module" { 
  source = "./module"

  resource_group_name   = module.resource_group.name
  region                = var.region
  ibmcloud_api_key      = var.ibmcloud_api_key
  resource_label        = "client2site"
  secrets_manager_guid  = module.secrets-manager.guid
  vpc_id                = module.subnets.vpc_id
  subnet_ids            = module.subnets.ids
}

resource local_file vpn_name {
  filename  = ".vpn_name"
  content   = module.vpn_module.name
}
