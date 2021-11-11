

resource null_resource update_vpc_infrastructure  {                                                      

    provisioner "local-exec" {                                                                          
        command = "ibmcloud plugin update vpc-infrastructure -f"
    }
}

module "vpn_module" { 
  source = "./module"

  resource_group_name = module.resource_group.name
  region = var.region
  ibmcloud_api_key = var.ibmcloud_api_key
  resource_label = "client2site"
  certificate_manager_id = module.cert-manager.id
  subnet_ids = module.subnets.ids
  depends_on = [
    module.cert-manager.name,
    null_resource.update_vpc_infrastructure
  ]
}
