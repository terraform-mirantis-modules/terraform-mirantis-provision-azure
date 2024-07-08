output "lb_id" {
  description = "The load balancer id"
  value       = azurerm_lb_backend_address_pool.ingress.id
}

output "lb_ingress" {
  description = "The load balancer rules"
  value       = azurerm_lb_rule.ingress
}

output "lb_ip" {
  description = "The load balancer url up"
  value       = azurerm_public_ip.ingress.ip_address
}
