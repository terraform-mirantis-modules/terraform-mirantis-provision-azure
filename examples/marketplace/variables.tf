variable "name" {
  description = "The name of the environment; also the resource group name"
  type        = string
}

variable "location" {
  description = "The location of the resource group"
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription id to use. Required, with no default: no subscription id is stored in this repository."
  type        = string
}

variable "ssh_pk_location" {
  description = "The location of the SSH private key"
  type        = string
  default     = ""
}

# === Network ===
variable "network" {
  description = "Network configuration"
  type = object({
    cidr               = string
    enable_vpn_gateway = bool
    enable_nat_gateway = bool
  })
  default = {
    cidr               = "172.31.0.0/16"
    enable_vpn_gateway = false
    enable_nat_gateway = false
  }
}

# === subnets ===
variable "subnets" {
  description = "Subnets configuration"
  type = map(object({
    cidr       = string
    nodegroups = list(string)
    private    = bool
  }))
  default = {}
}

# === Machines ===
variable "nodegroups" {
  description = "A map of machine group definitions. The machine `type` (linux/windows) is not declared here; it comes from the platform library entry, as do sku/offer/publisher/plan and the ssh user."
  type = map(object({
    platform = string
    // Azure VM size. Declared per nodegroup because the point of this example
    // is to run sizes other than the module default (Standard_DS2_v2).
    vm_size     = string
    count       = number
    volume_size = number
    role        = string
    public      = bool
    // Defaulted to "" rather than left null: modules/nodegroup_linux calls
    // base64encode(var.user_data), which rejects null. An empty value selects
    // the example_linux.tpl fallback in provision.tf, because the provider
    // also rejects an empty custom_data.
    user_data = optional(string, "")
    tags      = optional(map(string), {})
  }))

  validation {
    condition     = length([for k, ng in var.nodegroups : k if startswith(ng.platform, "rocky")]) > 0
    error_message = "This example exists to exercise the marketplace purchase-plan path; at least one nodegroup must use a rocky_* platform, which is the platform library's plan = true entry. Use examples/mke3 for a plain launchpad stack."
  }
}

variable "common_tags" {
  description = "Tags that should be applied to all resources created"
  type        = map(string)
  default     = {}
}
