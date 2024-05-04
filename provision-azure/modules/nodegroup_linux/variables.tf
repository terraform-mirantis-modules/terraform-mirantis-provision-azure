
variable "name" {
  description = "Node Group key"
  type        = string
}

variable "subnet_id" {
  description = "value of the subnet id"
  type        = string
}

variable "ssh_pub_key" {
  description = "SSH public key"
  type        = string
}

variable "type" {
  description = "The type of the machine"
  type        = string
}

variable "user" {
  description = "The user to create on the machine"
  type        = string
}

variable "vm_count" {
  description = "The number of instances to create"
  type        = number
}

variable "role" {
  description = "The role of the machine"
  type        = string
}

variable "public" {
  description = "Whether the machine is public"
  type        = bool
}

variable "user_data" {
  description = "The user data to pass to the machine"
  type        = string
}

variable "tags" {
  description = "The tags to apply to the machine"
  type        = map(string)
  default     = {}
}

variable "resource_group_name" {
  description = "The resource group to create the machine in"
  type        = string
}

variable "resource_group_location" {
  description = "The resource group to create the machine in"
  type        = string
}

variable "volume_size" {
  description = "The disk/volume size of the machine"
  type        = number
}
