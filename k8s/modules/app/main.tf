resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = var.app_namespace
  }

  data = {
    # app/main.go takes a single DATABASE_URL, not discrete host/port/etc.
    database_url = var.database_url
  }

  type = "Opaque"
}

resource "kubernetes_deployment" "demo_app" {
  metadata {
    name      = "demo-app"
    namespace = var.app_namespace
    labels = {
      app = "demo-app"
    }
  }

  spec {
    replicas = var.demo_app_replicas

    selector {
      match_labels = {
        app = "demo-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "demo-app"
        }

        # Picked up by the role: pod scrape job in the monitoring module.
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "8080"
          "prometheus.io/path"   = "/metrics"
        }
      }

      spec {
        container {
          name  = "app"
          image = "${var.ecr_repository_url}:${var.demo_app_image_tag}"

          port {
            container_port = 8080
          }

          env {
            name = "DATABASE_URL"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "database_url"
              }
            }
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "demo_app" {
  metadata {
    name      = "demo-app"
    namespace = var.app_namespace
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = "demo-app"
    }

    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
  }

  depends_on = [kubernetes_deployment.demo_app]
}

resource "kubernetes_ingress_v1" "demo_app" {
  metadata {
    name      = "demo-app"
    namespace = var.app_namespace
    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/certificate-arn" = var.acm_certificate_arn
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
      # external-dns reads this annotation to create the Route 53 A alias record.
      "external-dns.alpha.kubernetes.io/hostname" = "${var.app_subdomain}.${var.domain_name}"
    }
  }

  spec {
    rule {
      host = "${var.app_subdomain}.${var.domain_name}"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.demo_app.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
