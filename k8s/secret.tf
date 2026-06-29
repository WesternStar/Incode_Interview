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
    dbname   = data.terraform_remote_state.infra.outputs.rds_database_name
  }

  type = "Opaque"
}
