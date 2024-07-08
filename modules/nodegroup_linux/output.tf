output "ssh_key" {
  value = azurerm_linux_virtual_machine_scale_set.vmss.admin_ssh_key
}

data "azurerm_virtual_machine_scale_set" "hosts" {
  name                = azurerm_linux_virtual_machine_scale_set.vmss.name
  resource_group_name = var.resource_group_name
}

output "linux_hosts" {
  value = data.azurerm_virtual_machine_scale_set.hosts.instances
}
