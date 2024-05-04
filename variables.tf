variable "name" {
  description = "The name of the environment"
  type        = string
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
    user_data             = optional(string)
    instance_profile_name = optional(string)
    tags                  = optional(map(string), {})
  }))
  default = {}
}
