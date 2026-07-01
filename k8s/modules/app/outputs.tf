output "service_name" {
  description = "Name of the ClusterIP service in front of the demo app"
  value       = kubernetes_service.demo_app.metadata[0].name
}
