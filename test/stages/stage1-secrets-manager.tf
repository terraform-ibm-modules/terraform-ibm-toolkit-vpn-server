module "secrets-manager" {
  source = "github.com/cloud-native-toolkit/terraform-ibm-secrets-manager"

  resource_group_name = module.resource_group.name
  region              = var.region
  private_endpoint    = false
  trial               = false
}