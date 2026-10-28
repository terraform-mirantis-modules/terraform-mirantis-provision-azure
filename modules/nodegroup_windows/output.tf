// The scale set must exist before its instance list can be read. The ordering
// is made explicit rather than relying on the name attribute reference, which
// would stop ordering the read if the name were ever made a static string.
data "azurerm_virtual_machine_scale_set" "windows_hosts" {
  depends_on = [azurerm_windows_virtual_machine_scale_set.vmss]

  name                = azurerm_windows_virtual_machine_scale_set.vmss.name
  resource_group_name = var.resource_group_name
}

output "nodes" {
  value = { for nk, nv in data.azurerm_virtual_machine_scale_set.windows_hosts.instances : nk => nv }
}

output "user_data" {
  value = var.user_data
}
