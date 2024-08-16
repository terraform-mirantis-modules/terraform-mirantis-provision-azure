data "azurerm_virtual_machine_scale_set" "windows_hosts" {
  name                = azurerm_windows_virtual_machine_scale_set.vmss.name
  resource_group_name = var.resource_group_name
}

output "nodes" {
  value = { for nk, nv in data.azurerm_virtual_machine_scale_set.windows_hosts.instances : nk => nv }
}
