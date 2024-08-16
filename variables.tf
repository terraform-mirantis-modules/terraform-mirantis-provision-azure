
variable "name" {
  description = "cluster/stack name used for identification"
  type        = string
}

variable "location" {
  description = "Azure location for the resources"
  type        = string
}

variable "windows_password" {
  description = "Password to use with windows & winrm"
  type        = string
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

# === Firewalls ===
variable "securitygroups" {
  description = "Network Security group configuration per nodegroup"
  type = map(object({
    description = string
    nodegroups  = list(string) # which nodegroups should get attached to the sg?

    ingress_ipv4 = optional(list(object({
      description                = string
      from_port                  = string
      to_port                    = number
      protocol                   = string
      destination_address_prefix = string
      source_address_prefix      = string
      priority                   = number
    })), [])
    egress_ipv4 = optional(list(object({
      description                = string
      from_port                  = string
      to_port                    = number
      protocol                   = string
      destination_address_prefix = string
      source_address_prefix      = string
      priority                   = number
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
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
    volume_size           = number
    role                  = string
    public                = bool
    user                  = string
    user_data             = optional(string)
    instance_profile_name = optional(string)
    tags                  = optional(map(string), {})
  }))
  default = {}
}

# === Network ===
variable "network" {
  description = "Network configuration"
  type = object({
    cidr               = string
    enable_vpn_gateway = bool
    enable_nat_gateway = bool
  })
}

# === Common ===
variable "common_tags" {
  description = "Tags that should be applied to all resources created"
  type        = map(string)
  default     = {}
}

# === Ingresses ===
variable "ingresses" {
  description = "Configure ingress Load Balancer for specific nodegroup roles"
  type = map(object({
    description = string
    nodegroups  = list(string) # which nodegroups should get attached to the ingress

    routes = map(object({
      port_incoming = number
      port_target   = number
      protocol      = string
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}
