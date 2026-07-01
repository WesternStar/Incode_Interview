resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.monitoring_namespace
  }
}

# Grafana admin credentials, generated once and handed to the chart via
# grafana.admin.existingSecret so the password never lands in Terraform
# state as a helm `set` value (which would show up in plain text in the
# release's stored values).
resource "random_password" "grafana_admin" {
  length  = 24
  special = true
  # Avoid characters that commonly break basic-auth headers or shell copy/paste.
  override_special = "!#%^*-_=+"
}

resource "kubernetes_secret" "grafana_admin" {
  metadata {
    name      = "grafana-admin-credentials"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "admin-user"     = "admin"
    "admin-password" = random_password.grafana_admin.result
  }

  type = "Opaque"
}

locals {
  # Standard naming the kube-prometheus-stack chart gives its Grafana
  # subchart service: "<helm release name>-grafana".
  grafana_service_name = "${helm_release.kube_prometheus_stack.name}-grafana"

  # Annotation-based scrape config so app/main.go's /metrics endpoint gets
  # picked up without needing the Prometheus Operator's ServiceMonitor CRD
  # to already exist at plan time (a first-apply chicken-and-egg problem
  # for kubernetes_manifest resources). Pods opt in via the
  # prometheus.io/scrape annotation set on kubernetes_deployment.demo_app
  # in the app module, and on the YACE pod below.
  pod_annotation_scrape_config = {
    job_name = "kubernetes-pods"
    kubernetes_sd_configs = [
      { role = "pod" }
    ]
    relabel_configs = [
      {
        source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
        action        = "keep"
        regex         = "true"
      },
      {
        source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
        action        = "replace"
        target_label  = "__metrics_path__"
        regex         = "(.+)"
      },
      {
        source_labels = ["__address__", "__meta_kubernetes_pod_annotation_prometheus_io_port"]
        action        = "replace"
        regex         = "([^:]+)(?::\\d+)?;(\\d+)"
        replacement   = "$1:$2"
        target_label  = "__address__"
      },
      {
        source_labels = ["__meta_kubernetes_namespace"]
        target_label  = "namespace"
      },
      {
        source_labels = ["__meta_kubernetes_pod_name"]
        target_label  = "pod"
      }
    ]
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = var.kube_prometheus_stack_chart_version

  # This cluster has no EBS CSI driver / StorageClass installed, so every
  # component below runs with ephemeral (emptyDir) storage — metrics
  # history and Grafana dashboard edits are lost on pod restart. Fine for
  # a demo cluster; add the aws-ebs-csi-driver addon + a StorageClass and
  # a storageSpec/persistence block here if that durability is needed.
  values = [
    yamlencode({
      alertmanager = {
        # No receivers configured for this demo; drop it to save the extra pod.
        enabled = false
      }

      prometheus = {
        prometheusSpec = {
          retention = "24h"
          resources = {
            requests = { cpu = "100m", memory = "256Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }
          additionalScrapeConfigs = [local.pod_annotation_scrape_config]
        }
      }

      grafana = {
        admin = {
          existingSecret = kubernetes_secret.grafana_admin.metadata[0].name
          userKey        = "admin-user"
          passwordKey    = "admin-password"
        }
        persistence = {
          enabled = false
        }
        resources = {
          requests = { cpu = "50m", memory = "128Mi" }
          limits   = { cpu = "200m", memory = "256Mi" }
        }
        service = {
          type = "ClusterIP"
        }
      }

      kubeStateMetrics = {
        enabled = true
      }

      nodeExporter = {
        enabled = true
      }
    })
  ]
}

resource "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/certificate-arn" = var.acm_certificate_arn
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
      "external-dns.alpha.kubernetes.io/hostname" = "${var.grafana_subdomain}.${var.domain_name}"
    }
  }

  spec {
    rule {
      host = "${var.grafana_subdomain}.${var.domain_name}"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = local.grafana_service_name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.kube_prometheus_stack]
}

# RDS is a managed service with no /metrics endpoint of its own, so
# Prometheus can't scrape it directly. YACE polls the CloudWatch
# GetMetricData API for the RDS instance and re-exposes the results as
# normal Prometheus metrics, which the pod-annotation scrape config above
# then picks up like any other app pod.
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
          "eks.amazonaws.com/role-arn" = var.yace_role_arn
        }
      }

      # Picked up by the pod scrape job above.
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
