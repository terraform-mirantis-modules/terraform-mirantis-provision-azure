# This file contains the code to create a Windows Virtual Machine Scale Set
resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                = "Windows-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  sku                 = "Standard_DS2_v2"
  instances           = var.vm_count
  admin_username      = var.user
  admin_password      = var.windows_password

  computer_name_prefix = "${var.name}-"

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
    for_each = var.security_groups_ids
    content {
      name                      = "${var.name}-n-interface-${network_interface.key}"
      primary                   = var.security_groups_ids[0] == network_interface.value ? true : false
      network_security_group_id = network_interface.value

      ip_configuration {
        name                                   = "ipconfig-linux-${network_interface.key}"
        primary                                = var.security_groups_ids[0] == network_interface.value ? true : false
        subnet_id                              = var.subnet_id
        load_balancer_backend_address_pool_ids = var.lb_pool_ids

        public_ip_address {
          name = "${var.name}-ip-${network_interface.key}"
        }
      }
    }
  }
  tags = var.tags
}
