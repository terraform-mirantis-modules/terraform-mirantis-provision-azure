output "nodes" {
  description = "Nodegroups with node lists"
  value       = local.nodegroups
  sensitive   = true
}

output "ingresses" {
  description = "Ingresses with load balancer address information. lb_dns is the address clients connect to on port 443; the load balancer forwards to the route's port_target."
  value       = local.ingresses
}

output "platforms" {
  description = "Platform library entries resolved for the stack, including the plan flag that drives the marketplace purchase plan block"
  value       = local.platforms_with_sku
}

output "ssh_connections" {
  description = "SSH connection details per node. Read with: terraform output -json ssh_connections"
  sensitive   = true
  value = merge([for k, ng in local.nodegroups : {
    for n in ng.nodes : n.id => {
      address = n.public_ip
      user    = ng.ssh_user
      port    = ng.ssh_port
      keyPath = abspath(local_sensitive_file.ssh_private_key.filename)
    }
  }]...)
}
