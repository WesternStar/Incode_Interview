resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = var.app_namespace
  }

  data = {
    username = data.terraform_remote_state.infra.outputs.rds_username
    password = data.terraform_remote_state.infra.outputs.rds_password
    host     = data.terraform_remote_state.infra.outputs.rds_address
    port     = tostring(data.terraform_remote_state.infra.outputs.rds_port)
    dbname   = var.demo_app_db_name

    # app/main.go takes a single DATABASE_URL, not discrete host/port/etc.
    database_url = "postgres://${data.terraform_remote_state.infra.outputs.rds_username}:${data.terraform_remote_state.infra.outputs.rds_password}@${data.terraform_remote_state.infra.outputs.rds_address}:${data.terraform_remote_state.infra.outputs.rds_port}/${var.demo_app_db_name}"
  }

  type = "Opaque"
}
