# This file contains the code to create a Linux Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "Linux-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  sku                 = "Standard_DS2_v2"
  instances           = var.vm_count
  admin_username      = var.user

  admin_ssh_key {
    username   = var.user
    public_key = var.ssh_pub_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
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
