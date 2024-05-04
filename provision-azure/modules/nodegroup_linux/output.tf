output "ssh_key" {
  value = azurerm_linux_virtual_machine_scale_set.vmss.admin_ssh_key
}
