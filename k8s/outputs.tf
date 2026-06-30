output "app_url" {
  description = "Public HTTPS URL for the demo application"
  value       = "https://${var.app_subdomain}.${var.domain_name}"
}
