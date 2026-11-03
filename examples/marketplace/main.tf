locals {
  // Tags handed to the module as common_tags. The module merges its own
  // "stack" and "created" tags on top of these (main.tf at the repo root), so
  // they are not repeated here.
  tags = merge(
    { "example" = "marketplace" },
    var.common_tags,
  )
}
