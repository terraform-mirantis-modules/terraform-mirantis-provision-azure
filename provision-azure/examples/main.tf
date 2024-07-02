locals {
  // combine the nodegroup definition with the platform data
  nodegroups_wplatform = { for k, ngd in var.nodegroups : k => merge(ngd, local.platforms_with_sku[ngd.platform]) }
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
}

module "provision" {
  source = "../"

  name             = var.name
  location         = var.location
  windows_password = var.windows_password
  ingresses        = local.launchpad_ingresses
  network          = var.network
  subnets          = var.subnets

  nodegroups = { for k, ngd in local.nodegroups_wplatform : k => {
    sku : ngd.sku
    offer : ngd.offer
    publisher : ngd.publisher
    platform : ngd.platform
    type : ngd.type
    count : ngd.count
    volume_size : ngd.volume_size
    role : ngd.role
    public : ngd.public
    user_data : ngd.user_data
    user : ngd.user
  } }
  securitygroups = local.securitygroups
  extra_tags     = var.common_tags
}
