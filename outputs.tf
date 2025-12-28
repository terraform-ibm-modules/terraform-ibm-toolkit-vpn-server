
output "name" {
  description = "The name of the VPN server instance"
  value       = local.name
  depends_on  = [ibm_is_vpn_server.vpn_server]
}

output "server_certificate" {
  description = "The CRN of the server certificate saved to the certificate manager instance"
  value       = ibm_sm_imported_certificate.server_cert_secret.crn
}

output "client_certificate" {
  description = "The CRN of the client certificate saved to the certificate manager instance"
  value       = ibm_sm_imported_certificate.client_cert_secret.crn
}

output "vpn_profile" {
  description = "The filename of the VPN client configuration file"
  value       = local.vpn_profile
  depends_on  = [null_resource.client_profile]
}
