output "private_key" {
  value     = module.key.private_key
  sensitive = true
}

output "ingresses" {
  description = "Created ingress data including urls"
  value       = local.ingresses_withlb
}

output "nodegroups" {
  value = local.nodegroups_safer
}
