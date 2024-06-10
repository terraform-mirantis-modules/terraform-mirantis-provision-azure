variable "location" {
  description = "Location of the LB resources"
  type        = string
}

variable "rg_name" {
  description = "Resource group name"
  type        = string
}

variable "routes" {
  description = "What traffic should the ingress handle"
  type = map(object({
    port_incoming = number
    port_target   = number
    protocol      = string
  }))
}

variable "tags" {
  description = "tags to be applied to created resources"
  type        = map(string)
}

variable "name" {
  description = "Name of the ingress"
  type        = string
}
