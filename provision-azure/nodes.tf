
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

output "machine_sg" {
  value = data.azurerm_network_security_group.machine_sg
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

output "all_lb" {
  value = data.azurerm_lb.all_lb
}

locals {
  map_lb = { for ik, iv in var.ingresses : ik => [for ak, av in data.azurerm_lb.all_lb : av.id if av.name == ik] }
}

// mapping lb id to ingress name
output "mapped_lb" {
  value = local.map_lb
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

output "mapped_lb_pool" {
  value = local.map_lb_pools
}

# output "mngr_lbs" {
#   value = concat([], [for ik, iv in var.ingresses : local.map_lb[ik] if contains(iv.nodegroups, "AMngr")]...)
# }

module "linux_vmms" {
  for_each                = local.nodegroups_linux
  source                  = "./modules/nodegroup_linux"
  resource_group_name     = azurerm_resource_group.rg.name
  resource_group_location = azurerm_resource_group.rg.location
  name                    = var.name
  subnet_id               = azurerm_subnet.public_subnet.id
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
  user_data           = "test"
  lb_pool_ids         = concat([], [for ik, iv in var.ingresses : local.map_lb_pools[ik] if contains(iv.nodegroups, each.key)]...)
  security_groups_ids = concat([], [for mk, mv in local.map_sgs[each.key] : [for ak, av in data.azurerm_network_security_group.machine_sg : av.id if mv == av.name]]...)

  tags = merge({
    stack = var.name
    role  = each.value.role
  }, var.extra_tags)
}

// allowed values https://learn.microsoft.com/en-us/rest/api/compute/virtual-machines/create-or-update?view=rest-compute-2024-03-01&tabs=HTTP#osprofile
module "windows_vmms" {
  for_each                = local.nodegroups_windows
  source                  = "./modules/nodegroup_windows"
  resource_group_name     = azurerm_resource_group.rg.name
  resource_group_location = azurerm_resource_group.rg.location
  name                    = var.name
  subnet_id               = azurerm_subnet.public_subnet.id
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
  user_data           = "test"
  lb_pool_ids         = concat([], [for ik, iv in var.ingresses : local.map_lb_pools[ik] if contains(iv.nodegroups, each.key)]...)
  security_groups_ids = concat([], [for mk, mv in local.map_sgs[each.key] : [for ak, av in data.azurerm_network_security_group.machine_sg : av.id if mv == av.name]]...)

  tags = merge({
    stack = var.name
    role  = each.value.role
  }, var.extra_tags)
}
