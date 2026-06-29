output "demo_app_service_hostname" {
  description = "Public hostname of the demo app's LoadBalancer (may take a few minutes to populate)"
  value       = try(kubernetes_service.demo_app.status[0].load_balancer[0].ingress[0].hostname, "pending")
}
