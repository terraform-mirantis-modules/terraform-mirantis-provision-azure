// variables calculated before image data is retrieved
locals {
  // the distinct platform keys actually used by the nodegroups, so each
  // platform entry is resolved once
  unique_used_platforms = distinct([for ngd in var.nodegroups : ngd.platform])
}

module "platform" {
  count  = length(local.unique_used_platforms)
  source = "../../modules/platform"

  platform_key = local.unique_used_platforms[count.index]
}

locals {
  // nonsensitive() is required, not cosmetic. modules/platform marks its whole
  // output sensitive, but on azure that output is only the static library
  // entry (sku/offer/publisher/plan/connection/type); var.windows_password is
  // declared there and never reaches the output. The mark otherwise
  // propagates into every nodegroup built from it, and the root module filters
  // nodegroups with `if n.type == "linux"` (nodes.tf), which makes the
  // filtered collection sensitive and therefore invalid as a for_each
  // argument:
  //   Error: Invalid for_each argument ... local.nodegroups_linux has a
  //   sensitive value
  platforms_with_sku = { for k, p in local.unique_used_platforms : p => nonsensitive(module.platform[k].platform) }
}
