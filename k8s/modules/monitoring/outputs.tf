output "grafana_admin_password" {
  description = "Grafana admin password (username: admin)"
  value       = random_password.grafana_admin.result
  sensitive   = true
}
