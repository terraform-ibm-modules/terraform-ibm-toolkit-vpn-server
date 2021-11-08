# Client 2 Site VPN

This is a terraform module that will provision a client-to-site VPN on IBM Cloud.  _Note: This is a beta offering that is not supported by the IBM cloud Terraform provider yet, so it is implemented using a `local-exec` provisioner with a bash script to handle resource creation and configuration.

This module will: 

- Download necessary CLI dependencies (`jq`)
- Create a server and a client certificate and import them into a certificate manager instance
- Update the ACL for the VPC subnet to allow for VPN ingress & egress
- Create a security group and security group rules for the VPN server instance
- Provision a VPN server
- Download a VPNC Client profile and inject the client certificate so it is ready for use with an OpenVPN client

## Software dependencies

Dependencies:
- [CLIs](https://github.com/cloud-native-toolkit/terraform-util-clis)
- [Resource Group](https://github.com/cloud-native-toolkit/terraform-ibm-resource-group)
- [Certificate Manager](https://github.com/cloud-native-toolkit/terraform-ibm-cert-manager)
- [VPC](https://github.com/cloud-native-toolkit/terraform-ibm-vpc)
- [VPC Gateway](https://github.com/cloud-native-toolkit/terraform-ibm-vpc-gateways)
- [VPC Subnet](https://github.com/cloud-native-toolkit/terraform-ibm-vpc-subnets)

### Command-line tools

- `terraform` - v14
- `jq`
- `ibmcloud`

### Terraform providers

- IBM Cloud provider >= 1.35.0

## Example usage

```hcl-terraform
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
    module.cert-manager.name
  ]
}
```

