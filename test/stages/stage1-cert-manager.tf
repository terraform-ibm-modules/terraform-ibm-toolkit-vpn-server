#dependencies:
# - certificate manager instance already created
# - service auth already created


module "cert-manager" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-cert-manager"

  resource_group_name = module.resource_group.name
  region = var.region
  private_endpoint = false
}

module "service_auth" {
  source = "github.com/terraform-ibm-modules/terraform-ibm-toolkit-iam-service-authorization.git?ref=v1.2.13"

  ibmcloud_api_key    = var.ibmcloud_api_key
  source_service_name = "is" 
  source_resource_type = "flow-log-collector" #VPN Find ??
  #provision = true
  target_service_name = "cloud-object-storage" # Certifciate manager find from docs
  target_resource_group_id = module.resource_group.id
  roles = ["Writer"]
}