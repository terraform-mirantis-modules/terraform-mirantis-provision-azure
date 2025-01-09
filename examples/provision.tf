locals {
  // Example of user data for a Windows node via a template file
  # user_data_windows = templatefile("${path.module}/example.tpl", {
  #   user = "test",
  # })
  // combine the nodegroup definition with the platform data
  nodegroups_wplatform = { for k, ngd in var.nodegroups : k => merge(ngd, local.platforms_with_sku[ngd.platform]) }
}

module "provision" {
  source           = "../"
  name             = var.name
  location         = var.location
  windows_password = var.windows_password
  ingresses        = local.launchpad_ingresses
  network          = var.network
  subnets          = var.subnets

  nodegroups = { for k, ngd in local.nodegroups_wplatform : k => {
    source_image : {
      sku : ngd.sku
      offer : ngd.offer
      publisher : ngd.publisher
      version : "latest"
    }
    platform : ngd.platform
    type : ngd.type
    count : ngd.count
    volume_size : ngd.volume_size
    role : ngd.role
    public : ngd.public
    user_data : strcontains(ngd.platform, "windows") ? local.user_data_windows : ngd.user_data
    user : try(ngd.ssh_user, ngd.winrm_user)
  } }
  securitygroups = local.securitygroups
  common_tags    = var.common_tags
}

locals {
  // combine each node-group & platform definition with the provisioned nodes
  nodegroups = { for k, ngp in local.nodegroups_wplatform : k => merge({ "name" : k }, ngp, module.provision.nodegroups[k]) }
  ingresses  = { for k, i in local.launchpad_ingresses : k => merge({ "name" : k }, i, module.provision.ingresses[k]) }
}
