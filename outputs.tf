
output "name" {
  description = "The name of the VPN server instance"
  value       = local.name
  depends_on  = [null_resource.vpn_server]
}

output "server_certificate" {
  description = "The CRN of the server certificate saved to the certificate manager instance"
  value       = data.external.server-secret.result.crn
}

output "client_certificate" {
  description = "The CRN of the client certificate saved to the certificate manager instance"
  value       = data.external.client-secret.result.crn
}

output "vpn_profile" {
  description = "The filename of the VPN client configuration file"
  value       = local.vpn_profile
  depends_on  = [null_resource.client_profile]
}
