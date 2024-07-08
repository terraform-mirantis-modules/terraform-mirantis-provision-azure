
// variables calculated after ami data is pulled
locals {
  // combine ami/plaftorm data (and windows user data)
  platform_with_sku = local.lib_platform_definitions[var.platform_key]
}
