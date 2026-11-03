// The Windows/WinRM administrator password is generated unless the caller
// supplies one.
//
// An example that requires a password as an input invites a literal in a
// tfvars file or, worse, in a committed default - this repository's own
// history carries one from before the input existed. Generating by default
// removes the opportunity: nothing has to be typed, pasted or stored.
// An explicit value is still honoured, so existing callers that pass
// windows_password keep working unchanged.
//
// Azure requires 12-123 characters with three of {lower, upper, digit,
// special}; the minimums below guarantee all four. The special set
// excludes characters Azure rejects in passwords.

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
  description = "Windows/WinRM administrator password, supplied or generated. Read with: terraform output -raw windows_password"
  value       = local.windows_password
  sensitive   = true
}
