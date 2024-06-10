resource "tls_private_key" "rsa" {
  algorithm = "RSA"
}

resource "azurerm_ssh_public_key" "keypair" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  public_key          = tls_private_key.rsa.public_key_openssh
  tags = merge({
    stack     = var.name
    algorythm = "RSA"
    role      = "sshkey"
  }, var.tags)
}
