module "ingress" {
  for_each = var.ingresses
  source   = "./modules/ingress"

  name     = each.key
  location = azurerm_resource_group.rg.location
  rg_name  = azurerm_resource_group.rg.name
  routes   = each.value.routes
  tags     = local.tags
}

// calculated after lb is created
locals {
  // Add the lb for the lb to the ingress
  ingresses_withlb = { for k, i in var.ingresses : k => merge(i, module.ingress[k], { "lb_dns" : module.ingress[k].lb_dns }) }
}
