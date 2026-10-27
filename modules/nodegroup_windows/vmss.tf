# This file contains the code to create a Windows Virtual Machine Scale Set
resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                = "Windows-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  sku                 = var.vm_size
  instances           = var.vm_count
  admin_username      = var.winrm_user
  admin_password      = var.windows_password

  computer_name_prefix = var.name

  zone_balance = true
  zones        = [1, 2, 3]

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
      name                      = "${var.name}-n-interface-${network_interface.key}"
      network_security_group_id = var.network_security_group_id
      primary                   = var.subnets[0].id == network_interface.value.id ? true : false

      ip_configuration {
        name                                   = "ipconfig-win-${network_interface.key}-${basename(network_interface.value.id)}"
        primary                                = var.subnets[0].id == network_interface.value.id ? true : false
        subnet_id                              = network_interface.value.id
        load_balancer_backend_address_pool_ids = var.lb_pool_ids
        application_security_group_ids         = toset(var.app_security_group_ids)

        // if the subnet is private don't create a public ip address
        dynamic "public_ip_address" {
          for_each = network_interface.value.private ? [] : [1]
          content {
            name = "${var.name}-win-ip-${network_interface.key}-${basename(network_interface.value.id)}"
          }
        }
      }
    }
  }
  tags = var.tags
}
