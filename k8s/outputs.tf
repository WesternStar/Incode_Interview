output "app_url" {
  description = "Public HTTPS URL for the demo application"
  value       = "https://${var.app_subdomain}.${var.domain_name}"
}

output "grafana_url" {
  description = "Public HTTPS URL for Grafana"
  value       = "https://${var.grafana_subdomain}.${var.domain_name}"
}

output "grafana_admin_password" {
  description = "Grafana admin password (username: admin)"
  value       = module.monitoring.grafana_admin_password
  sensitive   = true
}
