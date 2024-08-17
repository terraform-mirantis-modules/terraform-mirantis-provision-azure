data "azurerm_application_security_group" "asg_in" {
  count               = length(var.app_security_group_names)
  name                = "${var.app_security_group_names[count.index]}-asg-inbound"
  resource_group_name = var.resource_group_name
}

data "azurerm_application_security_group" "asg_out" {
  count               = length(var.app_security_group_names)
  name                = "${var.app_security_group_names[count.index]}-asg-outbound"
  resource_group_name = var.resource_group_name
}

# This file contains the code to create a Linux Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "Linux-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  sku                 = "Standard_DS2_v2"
  instances           = var.vm_count
  admin_username      = var.ssh_user

  computer_name_prefix = var.name

  zone_balance = true
  zones        = [1, 2, 3]

  admin_ssh_key {
    username   = var.ssh_user
    public_key = var.ssh_pub_key
  }

  source_image_reference {
    publisher = var.source_image.publisher
    offer     = var.source_image.offer
    sku       = var.source_image.sku
    version   = var.source_image.version
  }

  custom_data = base64encode(var.user_data)

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = var.volume_size
  }

  dynamic "network_interface" {
    for_each = var.subnets
    content {
      name    = "${var.name}-n-interface-${network_interface.key}"
      primary = var.subnets[0].id == network_interface.value.id ? true : false

      ip_configuration {
        name                                   = "ipconfig-linux-${network_interface.key}-${basename(network_interface.value.id)}"
        primary                                = var.subnets[0].id == network_interface.value.id ? true : false
        subnet_id                              = network_interface.value.id
        load_balancer_backend_address_pool_ids = var.lb_pool_ids
        application_security_group_ids         = toset(concat([for asg in data.azurerm_application_security_group.asg_in : asg.id], [for asg in data.azurerm_application_security_group.asg_out : asg.id]))

        // if the subnet is private don't create a public ip address
        dynamic "public_ip_address" {
          for_each = network_interface.value.private ? [] : [1]
          content {
            name = "${var.name}-linux-ip-${network_interface.key}-${basename(network_interface.value.id)}"
          }
        }
      }
    }
  }
  tags = var.tags
}
