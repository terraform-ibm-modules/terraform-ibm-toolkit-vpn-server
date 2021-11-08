#dependencies:
# - certificate manager instance already created
# - service auth already created


module "cert-manager" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-cert-manager"

  resource_group_name = module.resource_group.name
  name = var.certificate_manager_instance_name
  private_endpoint = false
}

# module "flow_log_auth" {
#   source = "github.com/cloud-native-toolkit/terraform-ibm-iam-service-authorization"

#   source_service_name = "is"
#   source_resource_type = "flow-log-collector"
#   provision = true
#   target_service_name = "cloud-object-storage"
#   target_resource_group_id = module.resource_group.id
#   roles = ["Writer"]
# }