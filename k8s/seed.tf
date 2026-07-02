# One-off Job that loads the Chinook dataset into RDS. Runs against the
# server's maintenance `postgres` db — the seed SQL's `\c chinook_serial`
# creates the real database as a side effect (see app/README.md). The RDS
# security group only allows traffic from the EKS node security group, so
# this can't run from outside the cluster; a Job is the in-cluster
# equivalent of the `kubectl run` one-off pod described there.
resource "kubernetes_config_map" "seed_sql" {
  metadata {
    name      = "chinook-seed-sql"
    namespace = var.app_namespace
  }

  data = {
    "seed.sql" = file("${path.module}/../app/Chinook_PostgreSql_SerialPKs.sql")
  }
}

resource "kubernetes_job_v1" "seed_db" {
  metadata {
    name      = "chinook-seed"
    namespace = var.app_namespace
  }

  spec {
    backoff_limit = 2

    template {
      metadata {
        labels = { job = "chinook-seed" }
      }

      spec {
        restart_policy = "Never"

        container {
          name    = "seed"
          image   = "postgres:16-alpine"
          command = ["psql", "$(DATABASE_URL)", "-v", "ON_ERROR_STOP=1", "-f", "/seed/seed.sql"]

          env {
            name  = "DATABASE_URL"
            value = "postgres://${data.terraform_remote_state.infra.outputs.rds_username}:${data.terraform_remote_state.infra.outputs.rds_password}@${data.terraform_remote_state.infra.outputs.rds_address}:${data.terraform_remote_state.infra.outputs.rds_port}/postgres"
          }

          volume_mount {
            name       = "seed-sql"
            mount_path = "/seed"
          }
        }

        volume {
          name = "seed-sql"
          config_map {
            name = kubernetes_config_map.seed_sql.metadata[0].name
          }
        }
      }
    }
  }

  # Job specs are immutable — once this has run to completion, subsequent
  # applies leave it alone (no re-seeding) unless the seed SQL itself
  # changes, which forces replacement and reruns it.
  wait_for_completion = true

  timeouts {
    create = "5m"
  }
}
