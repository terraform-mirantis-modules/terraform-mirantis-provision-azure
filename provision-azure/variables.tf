
variable "name" {
  description = "cluster/stack name used for identification"
  type        = string
}

# ===  Networking ===
variable "network" {
  description = "Network configuration"
  type = object({
    cidr                 = string
    public_subnet_count  = number
    private_subnet_count = number
    enable_nat_gateway   = bool
    enable_vpn_gateway   = bool
  })
  default = {
    cidr                 = "172.31.0.0/16"
    public_subnet_count  = 3
    private_subnet_count = 0
    enable_nat_gateway   = false
    enable_vpn_gateway   = false
  }
}

# === Machines ===
variable "nodegroups" {
  description = "A map of machine group definitions"
  type = map(object({
    sku                   = string
    offer                 = string
    publisher             = string
    platform              = string
    type                  = string
    count                 = number
    root_device_name      = string
    volume_size           = number
    role                  = string
    public                = bool
    user_data             = optional(string)
    instance_profile_name = optional(string)
    tags                  = optional(map(string), {})
  }))
  default = {}
}

variable "extra_tags" {
  description = "Extra tags that will be added to all provisioned resources, where possible."
  type        = map(string)
  default     = {}
}

variable "windows_password" {
  description = "Password to use with windows & winrm"
  type        = string
  default     = ""
}

# # === Firewalls ===

# variable "securitygroups" {
#   description = "VPC Network Security group configuration"
#   type = map(object({
#     description = string
#     nodegroups  = list(string) # which nodegroups should get attached to the sg?

#     ingress_ipv4 = optional(list(object({
#       description = string
#       from_port   = number
#       to_port     = number
#       protocol    = string
#       cidr_blocks = list(string)
#       self        = bool
#     })), [])
#     egress_ipv4 = optional(list(object({
#       description = string
#       from_port   = number
#       to_port     = number
#       protocol    = string
#       cidr_blocks = list(string)
#       self        = bool
#     })), [])
#     tags = optional(map(string), {})
#   }))
#   default = {}
# }

# # === Ingresses ===

# variable "ingresses" {
#   description = "Configure ingress (ALB) for specific nodegroup roles"
#   type = map(object({
#     description = string
#     nodegroups  = list(string) # which nodegroups should get attached to the ingress

#     routes = map(object({
#       port_incoming = number
#       port_target   = number
#       protocol      = string
#     }))
#     tags = optional(map(string), {})
#   }))
#   default = {}
# }

# # === Common ===

# variable "common_tags" {
#   description = "Tags that should be applied to all resources created"
#   type        = map(string)
#   default     = {}
# }
