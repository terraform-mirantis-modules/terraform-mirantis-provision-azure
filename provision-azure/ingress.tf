module "ingress" {
  for_each = var.ingresses
  source   = "./modules/ingress"

  name     = each.key
  location = azurerm_resource_group.rg.location
  rg_name  = azurerm_resource_group.rg.name
  routes   = each.value.routes
  tags     = { stack = var.name }
}
