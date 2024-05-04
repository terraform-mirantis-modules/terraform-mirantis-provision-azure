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

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }

  custom_data = base64encode(var.user_data)

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = var.volume_size
  }

  network_interface {
    name    = "test-n-interface"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.subnet_id

      public_ip_address {
        name = "${var.name}-test-ip"
      }
    }
  }
}
