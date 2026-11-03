
// variables calculated before image data is retrieved
locals {
  // find the unique platforms actually used in the node_group_definitions, so that we can combine platform definiton and ami data together
  // - this is unique to avoid repeated ami pulls for the same definition
  // - only node-group platforms are pulled to avoid pulling images data sources that are not used anywhere
  unique_used_platforms = distinct([for ngd in var.nodegroups : ngd.platform])
}

module "platform" {
  count  = length(local.unique_used_platforms)
  source = "../../modules/platform"

  platform_key = local.unique_used_platforms[count.index]
}

// variables calculated after ami data is pulled
locals {
  // convert platform ami list to a map
  //
  // nonsensitive() is required, not cosmetic. modules/platform marks its whole
  // output sensitive, but on azure that output is only the static library entry
  // (sku/offer/publisher/connection/type) - var.windows_password is declared
  // there and never reaches the output. The sensitivity therefore carries no
  // secret, while it does propagate into every nodegroup built from it, and the
  // root module filters nodegroups with `if n.type == "linux"` (nodes.tf): a
  // collection filtered on a sensitive value is itself sensitive, which
  // terraform rejects as a for_each argument:
  //   Error: Invalid for_each argument ... local.nodegroups_linux has a
  //   sensitive value
  // Dropping the mark here keeps it off the for_each keys; the windows password
  // itself is still handled as sensitive, via local.windows_password.
  platforms_with_sku = { for k, p in local.unique_used_platforms : p => nonsensitive(module.platform[k].platform) }
}
