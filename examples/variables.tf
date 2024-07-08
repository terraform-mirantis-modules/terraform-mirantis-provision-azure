variable "name" {
  description = "The name of the environment"
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
  description = "A map of machine group definitions"
  type = map(object({
    platform              = string
    type                  = string
    count                 = number
    volume_size           = number
    role                  = string
    public                = bool
    user                  = optional(string)
    user_data             = optional(string)
    instance_profile_name = optional(string)
    tags                  = optional(map(string), {})
  }))
  default = {}
}

variable "location" {
  description = "The location of the resource group"
  type        = string
}

variable "windows_password" {
  description = "Password to use with windows & winrm"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Tags that should be applied to all resources created"
  type        = map(string)
  default     = {}
}
