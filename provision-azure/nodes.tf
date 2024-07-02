
locals {
  nodegroups_linux   = { for i, n in var.nodegroups : i => n if n.type == "linux" }
  nodegroups_windows = { for i, n in var.nodegroups : i => n if n.type == "windows" }
}

data "azurerm_network_security_group" "machine_sg" {
  depends_on          = [azurerm_network_security_group.machines]
  for_each            = var.securitygroups
  name                = each.key
  resource_group_name = azurerm_resource_group.rg.name
}

locals {
  map_sgs = { for nk, nv in var.nodegroups : nk => [for sgk, sgv in var.securitygroups : sgk if contains(sgv.nodegroups, nk)] }
}

resource "null_resource" "ingresses" {
  triggers = {
    count = length(module.ingress)
  }
}

data "azurerm_lb" "all_lb" {
  depends_on          = [null_resource.ingresses]
  for_each            = var.ingresses
  name                = each.key
  resource_group_name = azurerm_resource_group.rg.name
}

locals {
  map_lb = { for ik, iv in var.ingresses : ik => [for ak, av in data.azurerm_lb.all_lb : av.id if av.name == ik] }
}

// there is 1 to 1 mapping by name with the load balancer and the backend address pool
data "azurerm_lb_backend_address_pool" "all_lb_pool" {
  for_each        = data.azurerm_lb.all_lb
  loadbalancer_id = each.value.id
  name            = each.value.name
}

locals {
  map_lb_pools = { for ik, iv in var.ingresses : ik => [for ak, av in data.azurerm_lb_backend_address_pool.all_lb_pool : av.id if ak == ik] }
}

locals {
  map_nodegroups_to_subnets = { for nk, nv in var.nodegroups : nk => [for sk, sv in var.subnets : { id : sk, private : sv.private } if contains(sv.nodegroups, nk)] }
}

module "linux_vmms" {
  depends_on              = [azurerm_network_security_group.machines]
  for_each                = local.nodegroups_linux
  source                  = "./modules/nodegroup_linux"
  resource_group_name     = azurerm_resource_group.rg.name
  resource_group_location = azurerm_resource_group.rg.location
  name                    = each.key
  subnets                 = [for sk, sv in local.map_nodegroups_to_subnets[each.key] : { id : azurerm_subnet.all[sv.id].id, private : sv.private }]
  vm_count                = each.value.count
  user                    = each.value.user
  type                    = each.value.type
  role                    = each.value.role
  public                  = each.value.public
  ssh_pub_key             = module.key.public_key
  volume_size             = each.value.volume_size
  source_image = {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
    version   = "latest"
  }
  user_data                = "test"
  lb_pool_ids              = concat([], [for ik, iv in var.ingresses : local.map_lb_pools[ik] if contains(iv.nodegroups, each.key)]...)
  app_security_group_names = concat([], [for nk, nv in var.nodegroups : [for sgk, sgv in var.securitygroups : sgk if contains(sgv.nodegroups, nk)]]...)

  tags = merge({
    stack = var.name
    role  = each.value.role
  }, var.extra_tags)
}

// allowed values https://learn.microsoft.com/en-us/rest/api/compute/virtual-machines/create-or-update?view=rest-compute-2024-03-01&tabs=HTTP#osprofile
module "windows_vmms" {
  depends_on              = [azurerm_network_security_group.machines]
  for_each                = local.nodegroups_windows
  source                  = "./modules/nodegroup_windows"
  resource_group_name     = azurerm_resource_group.rg.name
  resource_group_location = azurerm_resource_group.rg.location
  subnets                 = [for sk, sv in local.map_nodegroups_to_subnets[each.key] : { id : azurerm_subnet.all[sv.id].id, private : sv.private }]
  name                    = each.key
  vm_count                = each.value.count
  user                    = each.value.user
  windows_password        = var.windows_password
  type                    = each.value.type
  role                    = each.value.role
  public                  = each.value.public
  ssh_pub_key             = module.key.public_key
  volume_size             = each.value.volume_size
  source_image = {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
    version   = "latest"
  }
  user_data                = "test"
  lb_pool_ids              = concat([], [for ik, iv in var.ingresses : local.map_lb_pools[ik] if contains(iv.nodegroups, each.key)]...)
  app_security_group_names = concat([], [for nk, nv in var.nodegroups : [for sgk, sgv in var.securitygroups : sgk if contains(sgv.nodegroups, nk)]]...)


  tags = merge({
    stack = var.name
    role  = each.value.role
  }, var.extra_tags)
}
