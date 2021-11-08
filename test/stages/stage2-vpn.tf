

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
  certificate_manager_instance_name = module.cert-manager.name
  vpc_id = module.vpc.id
  subnet_id = module.subnets.ids[0]
  depends_on = [
    module.cert-manager.name,
    null_resource.update_vpc_infrastructure
  ]
}
