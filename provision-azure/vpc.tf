# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = var.location
}

resource "azurerm_network_security_group" "main" {
  name                = "main-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "inbound_main"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "outbound_main"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = var.extra_tags
}

locals {
  app_sgs_inbound  = { for k, v in var.securitygroups : k => [for ik, iv in v.ingress_ipv4 : ik] }
  app_sgs_outbound = { for k, v in var.securitygroups : k => [for ik, iv in v.egress_ipv4 : ik] }
}

resource "azurerm_application_security_group" "machines_inbound" {
  for_each            = local.app_sgs_inbound
  name                = "${each.key}-asg-inbound"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  # tags                = merge(each.value.tags, var.extra_tags)
}

resource "azurerm_application_security_group" "machines_outbound" {
  for_each            = local.app_sgs_outbound
  name                = "${each.key}-asg-outbound"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  # tags                = merge(each.value.tags, var.extra_tags)
}

resource "azurerm_network_security_group" "machines" {
  for_each            = var.securitygroups
  name                = each.key
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  dynamic "security_rule" {
    for_each = each.value.ingress_ipv4
    content {
      name                                       = security_rule.value.description
      priority                                   = security_rule.value.priority
      direction                                  = "Inbound"
      access                                     = "Allow"
      protocol                                   = security_rule.value.protocol
      source_port_range                          = security_rule.value.from_port
      destination_port_range                     = security_rule.value.to_port
      source_address_prefix                      = security_rule.value.source_address_prefix
      destination_application_security_group_ids = [azurerm_application_security_group.machines_inbound[each.key].id]
    }
  }

  dynamic "security_rule" {
    for_each = each.value.egress_ipv4
    content {
      name                                  = security_rule.value.description
      priority                              = security_rule.value.priority
      direction                             = "Outbound"
      access                                = "Allow"
      protocol                              = security_rule.value.protocol
      source_port_range                     = security_rule.value.from_port
      destination_port_range                = security_rule.value.to_port
      destination_address_prefix            = security_rule.value.destination_address_prefix
      source_application_security_group_ids = [azurerm_application_security_group.machines_outbound[each.key].id]
    }
  }
  # tags = merge(each.value.tags, var.extra_tags)
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "vpc" {
  name                = "${var.name}-vpc"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [var.network.cidr]
}

locals {
  pub_subnets = { for k, v in var.subnets : k => v if v.private == false }
}

# Create a virtual network within the resource group
resource "azurerm_subnet" "all" {
  for_each                        = var.subnets
  name                            = "${each.key}-subnet"
  resource_group_name             = azurerm_resource_group.rg.name
  virtual_network_name            = azurerm_virtual_network.vpc.name
  address_prefixes                = [each.value.cidr]
  default_outbound_access_enabled = each.value.private ? false : true
}

resource "azurerm_public_ip" "subnet" {
  for_each            = local.pub_subnets
  name                = "${var.name}-${each.key}-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

// Create a public IP address
resource "azurerm_network_interface" "subnet" {
  for_each            = local.pub_subnets
  name                = "${each.key}-pub-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${each.key}-pub-ip-config"
    subnet_id                     = azurerm_subnet.all[each.key].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.subnet[each.key].id
  }
}

resource "azurerm_subnet_network_security_group_association" "public" {
  for_each                  = local.pub_subnets
  subnet_id                 = azurerm_subnet.all[each.key].id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_network_security_group" "public" {
  name                = "public-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "publicIn"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "publicOut"
    priority                   = 104
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
