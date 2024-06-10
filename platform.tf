
// variables calculated before ami data is retrieved
locals {
  // find the unique platforms actually used in the node_group_definitions, so that we can combine platform definiton and ami data together
  // - this is unique to avoid repeated ami pulls for the same definition
  // - only node-group platforms are pulled to avoid pulling images data sources that are not used anywhere
  unique_used_platforms = distinct([for ngd in var.nodegroups : ngd.platform])
}

module "platform" {
  count  = length(local.unique_used_platforms)
  source = "./provision-azure/modules/platform"

  platform_key = local.unique_used_platforms[count.index]
  #   windows_password = "dddTest!@"
}

// variables calculated after ami data is pulled
locals {
  // convert platform ami list to a map
  platforms_with_sku = { for k, p in local.unique_used_platforms : p => module.platform[k].platform }
}

output "unique_platforms" {
  value = local.platforms_with_sku
}
