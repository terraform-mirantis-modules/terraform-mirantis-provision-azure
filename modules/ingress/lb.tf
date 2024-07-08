resource "azurerm_public_ip" "ingress" {
  name                = "${var.name}-lb-pub-ip"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.rg_name}-${var.name}"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_lb" "ingress" {
  name                = var.name
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "${var.name}-lb"
    public_ip_address_id = azurerm_public_ip.ingress.id
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "ingress" {
  loadbalancer_id = azurerm_lb.ingress.id
  name            = var.name
}

resource "azurerm_lb_probe" "ingress" {
  for_each        = var.routes
  loadbalancer_id = azurerm_lb.ingress.id
  name            = "${each.value.port_target}-probe"
  port            = each.value.port_target
}

resource "azurerm_lb_rule" "ingress" {
  for_each                       = var.routes
  loadbalancer_id                = azurerm_lb.ingress.id
  name                           = each.key
  protocol                       = each.value.protocol
  frontend_port                  = each.value.port_incoming
  backend_port                   = each.value.port_target
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.ingress.id]
  frontend_ip_configuration_name = azurerm_lb.ingress.frontend_ip_configuration[0].name
  probe_id                       = [for pk, pv in azurerm_lb_probe.ingress : pv.id if pv.name == "${each.value.port_target}-probe"][0]
}
