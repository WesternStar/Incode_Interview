# RDS is a managed service with no /metrics endpoint of its own, so
# Prometheus can't scrape it directly. YACE polls the CloudWatch
# GetMetricData API for the RDS instance and re-exposes the results as
# normal Prometheus metrics, which the existing pod-annotation scrape
# config in monitoring.tf then picks up like any other app pod.
resource "helm_release" "yace" {
  name       = "yace"
  repository = "https://nerdswords.github.io/helm-charts"
  chart      = "yet-another-cloudwatch-exporter"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = var.yace_chart_version

  values = [
    yamlencode({
      serviceAccount = {
        create = true
        name   = "yace"
        annotations = {
          "eks.amazonaws.com/role-arn" = data.terraform_remote_state.infra.outputs.yace_role_arn
        }
      }

      # Picked up by the role: pod scrape job in monitoring.tf.
      podAnnotations = {
        "prometheus.io/scrape" = "true"
        "prometheus.io/port"   = "5000"
        "prometheus.io/path"   = "/metrics"
      }

      resources = {
        requests = { cpu = "50m", memory = "64Mi" }
        limits   = { cpu = "200m", memory = "128Mi" }
      }

      config = <<-EOT
        apiVersion: v1alpha1
        sts-region: ${var.aws_region}
        discovery:
          jobs:
            - type: AWS/RDS
              regions:
                - ${var.aws_region}
              period: 300
              length: 300
              metrics:
                - name: CPUUtilization
                  statistics: [Average]
                - name: DatabaseConnections
                  statistics: [Average]
                - name: FreeStorageSpace
                  statistics: [Average]
                - name: FreeableMemory
                  statistics: [Average]
                - name: ReadLatency
                  statistics: [Average]
                - name: WriteLatency
                  statistics: [Average]
      EOT
    })
  ]
}
