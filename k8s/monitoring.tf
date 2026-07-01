module "monitoring" {
  source = "./modules/monitoring"

  monitoring_namespace = var.monitoring_namespace
  grafana_subdomain    = var.grafana_subdomain
  domain_name          = var.domain_name
  acm_certificate_arn  = data.terraform_remote_state.infra.outputs.acm_certificate_arn

  kube_prometheus_stack_chart_version = var.kube_prometheus_stack_chart_version
  yace_chart_version                  = var.yace_chart_version

  aws_region    = var.aws_region
  yace_role_arn = data.terraform_remote_state.infra.outputs.yace_role_arn

  depends_on = [helm_release.aws_load_balancer_controller]
}
