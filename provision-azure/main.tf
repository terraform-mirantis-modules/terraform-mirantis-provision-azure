module "key" {
  source              = "./modules/key/rsa"
  name                = var.name
  resource_group_name = azurerm_resource_group.rg.name
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = var.name
  location = "West Europe"
}

resource "azurerm_network_security_group" "sg" {
  name                = "WideSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "in_rule" {
  name                        = "SSH"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.sg.name
}

# resource "azurerm_network_security_rule" "in_rule" {
#   name                        = "ALL"
#   priority                    = 100
#   direction                   = "Inbound"
#   access                      = "Allow"
#   protocol                    = "Tcp"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = azurerm_resource_group.rg.name
#   network_security_group_name = azurerm_network_security_group.sg.name
# }

// Create a public IP address
resource "azurerm_network_interface" "nic" {
  name                = "my-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "public-nic"
    subnet_id                     = azurerm_subnet.public_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "main" {
  name                = "${var.name}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [var.network.cidr]
}

# Create a virtual network within the resource group
resource "azurerm_subnet" "public_subnet" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.network.cidr]
}

resource "azurerm_public_ip" "public_ip" {
  name                = var.name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

locals {
  nodegroups_linux   = { for i, n in var.nodegroups : i => n if n.platform == "linux" }
  nodegroups_windows = { for i, n in var.nodegroups : i => n if n.platform == "windows" }
}

module "linux_vmms" {
  for_each                = local.nodegroups_linux
  source                  = "./modules/nodegroup_linux"
  resource_group_name     = azurerm_resource_group.rg.name
  resource_group_location = azurerm_resource_group.rg.location
  name                    = var.name
  subnet_id               = azurerm_subnet.public_subnet.id
  vm_count                = each.value.count
  # source_image_reference = // this needs to be added through list comprehansion where we resolve the platforms
  user        = "ubuntu" // this user needs to come from nodegroups list comprehansion
  type        = each.value.type
  role        = each.value.role
  public      = each.value.public
  ssh_pub_key = module.key.public_key
  volume_size = each.value.volume_size
  user_data   = "test"
  tags = {
    stack = var.name
    role  = each.value.role
  }
}

// allowed values https://learn.microsoft.com/en-us/rest/api/compute/virtual-machines/create-or-update?view=rest-compute-2024-03-01&tabs=HTTP#osprofile
module "windows_vmms" {
  for_each                = local.nodegroups_windows
  source                  = "./modules/nodegroup_windows"
  resource_group_name     = azurerm_resource_group.rg.name
  resource_group_location = azurerm_resource_group.rg.location
  name                    = var.name
  subnet_id               = azurerm_subnet.public_subnet.id
  vm_count                = each.value.count
  # source_image_reference = // this needs to be added through list comprehansion where we resolve the platforms
  user             = "dddtest" // this user needs to come from nodegroups list comprehansion
  windows_password = "P@ssw0rd123"
  type             = each.value.type
  role             = each.value.role
  public           = each.value.public
  ssh_pub_key      = module.key.public_key
  volume_size      = each.value.volume_size
  user_data        = "test"
  tags = {
    stack = var.name
    role  = each.value.role
  }
}

output "ssh_pk" {
  value     = module.key.private_key
  sensitive = true
}
