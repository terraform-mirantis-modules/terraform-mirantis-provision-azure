output "ssh_key" {
  value = azurerm_linux_virtual_machine_scale_set.vmss.admin_ssh_key
}

// The scale set must exist before its instance list can be read. The ordering
// is made explicit rather than relying on the name attribute reference, which
// would stop ordering the read if the name were ever made a static string.
data "azurerm_virtual_machine_scale_set" "hosts" {
  depends_on = [azurerm_linux_virtual_machine_scale_set.vmss]

  name                = azurerm_linux_virtual_machine_scale_set.vmss.name
  resource_group_name = var.resource_group_name
}

output "nodes" {
  value = { for nk, nv in data.azurerm_virtual_machine_scale_set.hosts.instances : nk => nv }
}
