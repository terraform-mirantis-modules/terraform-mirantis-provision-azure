output "keypair_id" {
  description = "Azure EC2 key-pair id"
  value       = azurerm_ssh_public_key.keypair.id
}

output "private_key" {
  description = "Private key contents"
  value       = tls_private_key.rsa.private_key_openssh
}

output "public_key" {
  description = "Value of the public key"
  value       = tls_private_key.rsa.public_key_openssh
}
