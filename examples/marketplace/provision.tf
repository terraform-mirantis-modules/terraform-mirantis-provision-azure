locals {
  // Every linux nodegroup needs user_data: modules/nodegroup_linux sets
  // custom_data = base64encode(var.user_data) unconditionally and the
  // provider rejects null and "" alike. Used when a nodegroup declares none.
  user_data_linux = templatefile("${path.module}/example_linux.tpl", {
    user = "test",
  })

  // combine the nodegroup definition with the platform data (sku, offer,
  // publisher, plan, ssh_user and the linux/windows type)
  nodegroups_wplatform = { for k, ngd in var.nodegroups : k => merge(ngd, local.platforms_with_sku[ngd.platform]) }
}

locals {
  // One security group for the whole stack. The root module applies only the
  // first security group of each nodegroup to the scale set NICs
  // (nodes.tf: local.map_sgs[each.key][0]), so a second group attached to the
  // same nodegroup would not be enforced.
  securitygroups = {
    "cluster" = {
      description = "Cluster traffic: ssh plus the ingress target port"
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
        },
        {
          // The load balancer translates 443 to this port, so the rule has to
          // name the target port, not the port the client connected to.
          description : "Ingress_Target_Inbound"
          from_port : "*"
          to_port : 33001
          protocol : "Tcp"
          source_address_prefix : "*"
          destination_address_prefix : "*"
          priority : 1002
        }
      ]

      // Deliberately empty. Azure applies its own default outbound rules
      // (AllowVnetOutBound, AllowInternetOutBound) to every NSG, so outbound
      // traffic still works without an explicit rule. The module no longer
      // ships allow-all groups, and consumers pass empty egress lists; this
      // proves that shape plans.
      egress_ipv4 = []

      tags = local.tags
    }
  }

  // A port-translating route: clients connect to 443 on the load balancer and
  // are forwarded to 33001 on the nodes. azurerm_lb_rule carries
  // frontend_port = 443 with backend_port = 33001.
  cluster_ingresses = {
    "cluster" = {
      description = "Cluster entrypoint with port translation"
      nodegroups  = [for n, ng in var.nodegroups : n if ng.role == "manager"]

      routes = {
        "https" = {
          port_incoming = 443
          port_target   = 33001
          protocol      = "Tcp"
        }
      }
      tags = local.tags
    }
  }
}

module "provision" {
  source = "../../"

  name             = var.name
  location         = var.location
  windows_password = local.windows_password
  network          = var.network
  subnets          = var.subnets
  ingresses        = local.cluster_ingresses
  securitygroups   = local.securitygroups
  common_tags      = local.tags

  nodegroups = { for k, ngd in local.nodegroups_wplatform : k => {
    source_image : {
      sku : ngd.sku
      offer : ngd.offer
      publisher : ngd.publisher
      version : "latest"
      // true for the rocky platforms, which are marketplace images with a
      // purchase plan; the nodegroup modules then emit the plan block. The
      // Canonical entries carry plan = false and must not send one.
      plan : try(ngd.plan, false)
    }
    platform : ngd.platform
    type : ngd.type
    vm_size : ngd.vm_size
    count : ngd.count
    volume_size : ngd.volume_size
    role : ngd.role
    public : ngd.public
    user_data : ngd.user_data != "" ? ngd.user_data : local.user_data_linux
    user : ngd.ssh_user
    tags : merge(ngd.tags, local.tags)
  } }
}

locals {
  // combine each nodegroup & platform definition with the provisioned nodes
  nodegroups = { for k, ngp in local.nodegroups_wplatform : k => merge({ "name" : k }, ngp, module.provision.nodegroups[k]) }
  ingresses  = { for k, i in local.cluster_ingresses : k => merge({ "name" : k }, i, module.provision.ingresses[k]) }
}
