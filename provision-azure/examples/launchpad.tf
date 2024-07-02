locals {
  securitygroups = {
    "common" = {
      description = "Common SG for all cluster machines"
      nodegroups  = [for n, ng in var.nodegroups : n] // TODO: We can have different SGs based on the nodegroups
      ingress_ipv4 = [
        {
          description : "SSH_Inbound"
          from_port : "*"
          to_port : 22
          protocol : "Tcp"
          source_address_prefix : "*"
          destination_address_prefix : "*"
          priority : 1001
        }
      ]
      egress_ipv4 = [
        {
          description : "SSH_Outbound"
          from_port : "*"
          to_port : 22
          protocol : "Tcp"
          source_address_prefix : "*"
          destination_address_prefix : "*"
          priority : 1002
        }
      ]
    }
    "launchpad" = {
      description = "Launchpad SG for all cluster machines"
      nodegroups  = [for n, ng in var.nodegroups : n] // TODO: We can have different SGs based on the nodegroups
      ingress_ipv4 = [
        {
          description : "HTTPs_Inbound"
          from_port : "*"
          to_port : 443
          protocol : "Tcp"
          source_address_prefix : "*"
          destination_address_prefix : "*"
          priority : 1003
        }
      ]
      egress_ipv4 = [
        {
          description : "HTTPs_Outbound"
          from_port : "*"
          to_port : 443
          protocol : "Tcp"
          source_address_prefix : "*"
          destination_address_prefix : "*"
          priority : 1004
        }
      ]
    }
  }
}
