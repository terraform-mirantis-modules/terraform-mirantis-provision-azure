output "nodes" {
  description = "Nodegroups with node lists"
  value       = local.nodegroups
  sensitive   = true
}

output "ingresses" {
  description = "Ingresses with load balancer address information"
  value       = local.ingresses
}

output "platforms" {
  description = "Platforms used in the stack, as resolved by modules/platform"
  value       = local.platforms_with_sku
}
