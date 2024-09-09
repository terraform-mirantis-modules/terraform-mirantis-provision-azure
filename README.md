# Provisioning Azure infrastructure for Mirantis Launchpad

This repository contains Terraform configuration files for provisioning resources on Azure dedicated to support Mirantis products.

## Prerequisites

Before you begin, ensure that you have the following:

- Terraform installed on your local machine
- Azure account and project set up


## Usage
```hcl
module "provision" {
  source = "terraform-mirantis-modules/provision-azure/mirantis"

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
    user : try(ngd.ssh_user, ngd.winrm_user)
  } }
  securitygroups = local.securitygroups
  common_tags    = var.common_tags
}
```

## Examples
If you want to see full example, check the [examples folder](./examples).

## License

This project is licensed under the [MIT License].
