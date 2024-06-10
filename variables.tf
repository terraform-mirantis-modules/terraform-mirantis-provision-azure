variable "name" {
  description = "The name of the environment"
  type        = string
}

variable "ssh_pk_location" {
  description = "The location of the SSH private key"
  type        = string
  default     = ""
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
  default     = "West Europe"
}

variable "common_tags" {
  description = "Tags that should be applied to all resources created"
  type        = map(string)
  default     = {}
}
