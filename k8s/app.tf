module "app" {
  source = "./modules/app"

  app_namespace      = var.app_namespace
  demo_app_replicas  = var.demo_app_replicas
  ecr_repository_url = local.ecr_repository_url
  demo_app_image_tag = var.demo_app_image_tag

  # app/main.go takes a single DATABASE_URL, not discrete host/port/etc.
  database_url = "postgres://${data.terraform_remote_state.infra.outputs.rds_username}:${data.terraform_remote_state.infra.outputs.rds_password}@${data.terraform_remote_state.infra.outputs.rds_address}:${data.terraform_remote_state.infra.outputs.rds_port}/${var.demo_app_db_name}"

  app_subdomain       = var.app_subdomain
  domain_name         = var.domain_name
  acm_certificate_arn = data.terraform_remote_state.infra.outputs.acm_certificate_arn

  depends_on = [helm_release.aws_load_balancer_controller]
}
