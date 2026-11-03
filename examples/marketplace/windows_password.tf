// This example provisions no windows nodes, but the module's
// windows_password input is required and has no default (variables.tf at the
// repo root), so a value has to be produced anyway. It is generated rather
// than defaulted to a literal: a literal in an example invites it into a
// tfvars file or a commit, which is what put a password into this
// repository's history before the input existed.
//
// An explicit value is still honoured. Azure requires 12-123 characters with
// three of {lower, upper, digit, special}; the minimums below guarantee all
// four, and the special set excludes characters Azure rejects.

variable "windows_password" {
  description = "Password to use with windows & winrm. Leave empty (the default) to have one generated; read it back with `terraform output -raw windows_password`."
  type        = string
  default     = ""
  sensitive   = true
}

resource "random_password" "windows" {
  count = var.windows_password == "" ? 1 : 0

  length  = 24
  special = true

  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1

  override_special = "!#$%&*()-_=+[]<>:?"
}

locals {
  windows_password = var.windows_password != "" ? var.windows_password : random_password.windows[0].result
}

output "windows_password" {
  description = "Windows/WinRM administrator password, supplied or generated. Unused by this example's nodegroups; present because the module requires the input. Read with: terraform output -raw windows_password"
  value       = local.windows_password
  sensitive   = true
}
