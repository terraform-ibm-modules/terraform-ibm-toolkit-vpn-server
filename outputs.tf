


output "name" {
  description = "The name of the VPN server instance"
  value       = local.name
  depends_on  = [null_resource.vpn_server]
}


output "server_certificate" {
  description = "The id of the server certificate saved to the certificate manager instance"
  value       = ibm_certificate_manager_import.server_cert.id
}

output "client_certificate" {
  description = "The id of the client certificate saved to the certificate manager instance"
  value       = ibm_certificate_manager_import.client_cert.id
}




output "vpn_profile" {
  description = "The id of the VPN server instance"
  value       = local.vpn_profile
  depends_on  = [null_resource.client_profile]
}