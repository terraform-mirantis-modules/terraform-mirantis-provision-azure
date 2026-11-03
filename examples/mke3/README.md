# Example: MKE 3 cluster on Azure

Provisions a Mirantis Kubernetes Engine 3.x stack with this module - a
resource group, virtual network, subnets, network security groups,
application security groups, a load balancer ingress and one scale set per
nodegroup - then renders a `launchpad.yaml` from the live addresses.

The bundled `terraform.tfvars.example` builds a mixed stack: one Ubuntu
22.04 manager and one Windows 2022 node, which exercises both
`modules/nodegroup_linux` and `modules/nodegroup_windows`.

For the marketplace-image, non-default `vm_size`, port-translating ingress
and empty-egress securitygroup cases see [`../marketplace`](../marketplace).

## Prerequisites

- Terraform >= 1.0
- An authenticated Azure session (`az login`) and the id of the
  subscription to build in
- `launchpad` CLI for the install step

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: name, location, launchpad.mke_connect credentials,
# nodegroup counts and sizes

terraform init
terraform plan  -var "subscription_id=<your-azure-subscription-id>"
terraform apply -var "subscription_id=<your-azure-subscription-id>"

terraform output -raw launchpad_yaml > launchpad.yaml
launchpad apply -c launchpad.yaml
```

`subscription_id` is a required input with no default and is deliberately
not stored in the repository; pass it on the command line, in a tfvars file
kept outside the repository, or set `ARM_SUBSCRIPTION_ID` in the
environment.

Tear down with `terraform destroy` plus the same `subscription_id`.

## Inputs

| Variable | Description | Default |
|---|---|---|
| `name` | Stack name; also the resource group name | - |
| `location` | Azure location, e.g. `East US` | - |
| `subscription_id` | Subscription to build in | - |
| `network` | Virtual network CIDR and gateway flags | `172.31.0.0/16`, no NAT/VPN |
| `subnets` | Subnet CIDRs mapped to nodegroups | `{}` |
| `nodegroups` | Nodegroup definitions (platform, type, count, role, volume_size, public) | `{}` |
| `launchpad` | MCR/MKE/MSR versions and MKE admin credentials | - |
| `ssh_pk_location` | Directory to write the generated SSH private key | `./ssh-keys/` |
| `windows_password` | Windows/WinRM administrator password; generated when empty | `""` |
| `common_tags` | Tags applied to every resource that supports them | `{}` |

## Outputs

| Output | Description |
|---|---|
| `launchpad_yaml` | Rendered `launchpad.yaml` ready for `launchpad apply` (sensitive) |
| `windows_password` | The supplied or generated Windows password (sensitive) |
| `nodes` | Provisioned node details per nodegroup (sensitive) |
| `ingresses` | Ingress definitions merged with the load balancer address |
| `platforms` | Platform library entries resolved for the stack |

## Notes

Every linux nodegroup is given `user_data`: `modules/nodegroup_linux` sets
`custom_data = base64encode(var.user_data)` unconditionally, and the azurerm
provider rejects both a null and an empty `custom_data`. When a nodegroup
declares none, `example_linux.tpl` is used; windows nodegroups get
`example.tpl`.

`modules/platform` marks its whole output sensitive. On Azure that output is
only the static platform library entry, so `platform.tf` strips the mark with
`nonsensitive()`. Without it the root module's `if n.type == "linux"` filter
over `var.nodegroups` produces a sensitive collection, and Terraform refuses
it as a `for_each` argument.
