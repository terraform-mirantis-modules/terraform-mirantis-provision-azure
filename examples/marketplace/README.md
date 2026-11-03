# Example: marketplace image, sized VMs, port-translating ingress

A two-nodegroup stack that exercises the parts of the module no other
example reaches. Each is in production use by consumers of this module, and
each has a branch in the module that is otherwise never planned:

- **a marketplace image with a purchase plan.** `rocky_9` (and `rocky_8`)
  carry `plan = true` in the platform library, which makes
  `modules/nodegroup_linux` emit a `plan { name, publisher, product }` block
  on the scale set. The Canonical worker carries `plan = false` and must not
  send one; both branches appear in a single plan.
- **non-default `vm_size`.** The module default is `Standard_DS2_v2`; this
  example runs `Standard_D4as_v5` for the manager and `Standard_D2as_v5` for
  the worker.
- **a port-translating ingress route**, `port_incoming = 443` with
  `port_target = 33001`. The Azure load balancer does the translation itself:
  `azurerm_lb_rule` gets `frontend_port = 443`, `backend_port = 33001`. The
  security group rule names the target port, not the client-facing one.
- **`egress_ipv4 = []`** on the securitygroup. The module no longer ships
  allow-all network security groups, so consumers pass empty egress lists and
  rely on Azure's own default outbound rules (`AllowVnetOutBound`,
  `AllowInternetOutBound`). The NSG then plans with inbound rules only.

For a full launchpad/MKE stack, including windows nodes, use
[`../mke3`](../mke3).

## Prerequisites

- Terraform >= 1.0
- An authenticated Azure session (`az login`) and the id of the subscription
  to build in
- For an **apply** (not needed for a plan): the marketplace terms for the
  rocky image accepted once per subscription

  ```bash
  az vm image terms accept --urn resf:rockylinux-x86_64:9-base:latest
  ```

## Running it

```bash
cp terraform.tfvars.example terraform.tfvars
# edit: name (must be unique per stack), location, vm_size, counts

terraform init
terraform plan  -var "subscription_id=<your-azure-subscription-id>"
terraform apply -var "subscription_id=<your-azure-subscription-id>"
```

`subscription_id` is required and has no default; no subscription id is
stored in this repository. Pass it on the command line, in a tfvars file
kept outside the repository, or set `ARM_SUBSCRIPTION_ID`.

Read the results:

```bash
terraform output -json ingresses       # lb_dns: connect to it on 443
terraform output -json ssh_connections # address, user, port, keyPath per node
terraform output -json platforms       # resolved sku/offer/publisher/plan
```

Traffic arriving on `lb_dns:443` is forwarded to port 33001 on the manager
nodes, so a listener has to be bound to 33001 there before the probe passes.

Tear it down when finished:

```bash
terraform destroy -var "subscription_id=<your-azure-subscription-id>"
```

## Inputs

| Variable | Description | Default |
|---|---|---|
| `name` | Stack name; also the resource group name | - |
| `location` | Azure location, e.g. `East US` | - |
| `subscription_id` | Subscription to build in | - |
| `network` | Virtual network CIDR and gateway flags | `172.31.0.0/16`, no NAT/VPN |
| `subnets` | Subnet CIDRs mapped to nodegroups | `{}` |
| `nodegroups` | Nodegroup definitions; `vm_size` is declared per group | - |
| `ssh_pk_location` | Directory to write the generated SSH private key | `./ssh-keys/` |
| `windows_password` | Generated when empty. No windows node is provisioned here; the module's input is required, so a value is still produced | `""` |
| `common_tags` | Tags applied to every resource that supports them | `{}` |

## Outputs

| Output | Description |
|---|---|
| `nodes` | Provisioned node details per nodegroup (sensitive) |
| `ingresses` | Ingress definitions merged with the load balancer address |
| `platforms` | Platform library entries resolved for the stack |
| `ssh_connections` | Address, user, port and key path per node (sensitive) |
| `windows_password` | Generated password, unused by this stack (sensitive) |

## Notes

Only the **first** security group listed for a nodegroup reaches the scale
set NICs: the root module passes
`local.map_sgs[each.key][0]` as `network_security_group_id` (`nodes.tf`).
This example therefore uses one security group for the whole stack rather
than splitting rules across several.

`modules/platform` marks its whole output sensitive. On Azure that output is
only the static platform library entry, so `platform.tf` strips the mark with
`nonsensitive()`; without it the root module's `if n.type == "linux"` filter
yields a sensitive collection, which Terraform rejects as a `for_each`
argument.

Every linux nodegroup is given `user_data`, from `example_linux.tpl` when the
nodegroup declares none: `modules/nodegroup_linux` sets
`custom_data = base64encode(var.user_data)` unconditionally and the provider
rejects both a null and an empty `custom_data`.
