// constants
locals {

  // role for MSR machines, so that we can detect if msr config is needed
  launchpad_role_msr = "msr"
  // only hosts with these roles will be used for launchpad_yaml
  launchpad_roles = ["manager", "worker", local.launchpad_role_msr]
}

// Launchpad configuration
variable "launchpad" {
  description = "launchpad install configuration"
  type = object({
    drain = bool

    mcr_version = string
    mke_version = string
    msr_version = string // unused if you have no MSR hosts

    mke_connect = object({
      username = string
      password = string
      insecure = bool // true if this endpoint will not use a valid certificate
    })

    skip_create  = bool
    skip_destroy = bool
  })
}

locals {
  launchpad_ingresses = {
    "mke" = {
      description = "MKE ingress for UI and Kube"
      nodegroups  = [for k, ng in var.nodegroups : k if ng.role == "manager"]

      routes = {
        "mke" = {
          port_incoming = 443
          port_target   = 443
          protocol      = "Tcp"
        }
        "kube" = {
          port_incoming = 6443
          port_target   = 6443
          protocol      = "Tcp"
        }
      }
    }
  }
  securitygroups = {
    "common" = {
      description = "Common SG for all cluster machines"
      nodegroups  = [for n, ng in var.nodegroups : n]
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
      nodegroups  = [for n, ng in var.nodegroups : n]
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
    # Example of a Windows specific security group
    "windows" = {
      description = "Windows SG for the Windows machines"
      nodegroups  = [for n, ng in var.nodegroups : n] # if n == "AWrkr"]
      ingress_ipv4 = [
        {
          description : "WinRM_Inbound"
          from_port : "*"
          to_port : 5986
          protocol : "Tcp"
          source_address_prefix : "*"
          destination_address_prefix : "*"
          priority : 1005
        },
        {
          description : "WinRDP_Inbound"
          from_port : "*"
          to_port : 3389
          protocol : "Tcp"
          source_address_prefix : "*"
          destination_address_prefix : "*"
          priority : 1007
        }
      ]
      egress_ipv4 = [
        {
          description : "WinRM_Outbound"
          from_port : "*"
          to_port : 5986
          protocol : "Tcp"
          source_address_prefix : "*"
          destination_address_prefix : "*"
          priority : 1006
        },
        {
          description : "WinRDP_Outbound"
          from_port : "*"
          to_port : 3389
          protocol : "Tcp"
          source_address_prefix : "*"
          destination_address_prefix : "*"
          priority : 1008
        }
      ]
    }
  }
}


// locals calculated before the provision run
locals {
  // decide if we need msr configuration (the [0] is needed to prevent an error of no msr instances exit)
  has_msr = sum(concat([0], [for k, ng in var.nodegroups : ng.count if ng.role == local.launchpad_role_msr])) > 0
}

locals {
  // collect all launchpad related ingresses, depending on whether or not msr is included
  combined_ingresses = local.ingresses //merge(local.mke_ingresses, local.has_msr ? local.msr_ingresses : {})
  // collect all launchpad related SGs, depending on whether or not msr is included
  combined_securitygroups = local.securitygroups //merge(local.mke_securitygroups, local.has_msr ? local.msr_securitygroups : {})
}

// prepare values to make it easier to feed into launchpad
locals {
  // The SAN URL for the MKE load balancer ingress that is for the MKE load balancer
  MKE_URL = module.provision.ingresses["mke"].lb_dns

  // The SAN URL for the MKE load balancer ingress that is for the MKE load balancer
  # MSR_URL = module.provision.ingresses["msr"].lb_dns
  MSR_URL = ""
}

locals {
  // flatten nodegroups into a set of objects with the info needed for each node, by combining the group details with the node detains
  launchpad_hosts_ssh = merge([for k, ng in local.nodegroups : { for l, ngn in ng.nodes : ngn.instance_id => {
    # label : ngn.label // it's a map of strings
    id : ngn.instance_id
    role : ng.role

    address : ngn.public_address

    ssh_address : ngn.public_ip
    ssh_user : ng.ssh_user
    ssh_port : ng.ssh_port
    ssh_key_path : abspath(local_sensitive_file.ssh_private_key.filename)
  } if contains(local.launchpad_roles, ng.role) && ng.connection == "ssh" }]...)

  launchpad_hosts_winrm = merge([for k, ng in local.nodegroups : { for l, ngn in ng.nodes : ngn.instance_id => {
    # label : ngn.label
    id : ngn.instance_id
    role : ng.role

    address : ngn.public_address

    winrm_address : ngn.public_ip
    winrm_user : ng.winrm_user
    winrm_password : var.windows_password
    winrm_useHTTPS : ng.winrm_useHTTPS
    winrm_insecure : ng.winrm_insecure
  } if contains(local.launchpad_roles, ng.role) && ng.connection == "winrm" }]...)

}

output "launchpad_yaml" {
  description = "launchpad config file yaml (for debugging)"
  sensitive   = true
  value       = <<-EOT
apiVersion: launchpad.mirantis.com/mke/v1.4
kind: mke%{if local.has_msr}+msr%{endif}
metadata:
  name: ${var.name}
spec:
  cluster:
    prune: true
  hosts:
%{~for h in local.launchpad_hosts_ssh}
  # (id) ${h.id} (ssh)
  - role: ${h.role}
    ssh:
      address: ${h.ssh_address}
      user: ${h.ssh_user}
      keyPath: ${h.ssh_key_path}
%{~endfor}
%{~for h in local.launchpad_hosts_winrm}
  # (id) ${h.id} (winrm)
  - role: ${h.role}
    winRM:
      address: ${h.winrm_address}
      user: ${h.winrm_user}
      password: ${h.winrm_password}
      useHTTPS: ${h.winrm_useHTTPS}
      insecure: ${h.winrm_insecure}
%{~endfor}
  mke:
    version: ${var.launchpad.mke_version}
    imageRepo: docker.io/mirantis
    adminUsername: ${var.launchpad.mke_connect.username}
    adminPassword: ${var.launchpad.mke_connect.password}
    installFlags:
    - "--san=${local.MKE_URL}"
    - "--force-minimums"
  mcr:
    version: ${var.launchpad.mcr_version}
    repoURL: https://repos.mirantis.com
    channel: stable
%{if local.has_msr}
  msr:
    version: ${var.launchpad.msr_version}
    imageRepo: docker.io/mirantis
    replicaIDs: sequential
    installFlags:
    - "--ucp-insecure-tls"
    - "--dtr-external-url=${local.MSR_URL}"
%{endif}
EOT

}
