module "key" {
  source = "./modules/key/rsa"

  name                = "${var.name}-common"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags
}
