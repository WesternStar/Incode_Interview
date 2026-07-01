variable "aws_region" {
  description = "AWS region the EKS cluster lives in (used only for `aws eks get-token` auth, no AWS resources are managed here)"
  type        = string
  default     = "us-east-1"
}

variable "infra_state_path" {
  description = "Path to the aws_infra/ Terraform state file, used to look up cluster/RDS details"
  type        = string
  default     = "../aws_infra/terraform.tfstate"
}

variable "app_namespace" {
  description = "Namespace to deploy the demo app into"
  type        = string
  default     = "default"
}

variable "demo_app_image_tag" {
  description = "Tag to deploy from the ECR repo created in aws_infra/ (build/push app/ there first)"
  type        = string
  default     = "latest"
}

variable "demo_app_db_name" {
  description = "Database the demo app connects to — the Chinook seed script always creates/populates a database with this exact name regardless of the RDS instance's initial db_name (see app/README.md)"
  type        = string
  default     = "chinook_serial"
}

variable "demo_app_replicas" {
  description = "Number of replicas for the demo application"
  type        = number
  default     = 2
}

variable "domain_name" {
  description = "Root domain used for the app Ingress (must match the Route 53 zone in aws_infra/)"
  type        = string
}

variable "app_subdomain" {
  description = "Subdomain for the demo app (e.g. 'music' → music.example.com)"
  type        = string
  default     = "music"
}

variable "monitoring_namespace" {
  description = "Namespace for the kube-prometheus-stack (Prometheus, Grafana, Alertmanager)"
  type        = string
  default     = "monitoring"
}

variable "grafana_subdomain" {
  description = "Subdomain for the Grafana Ingress (e.g. 'grafana' → grafana.example.com)"
  type        = string
  default     = "grafana"
}

variable "kube_prometheus_stack_chart_version" {
  description = "Version of the prometheus-community/kube-prometheus-stack Helm chart"
  type        = string
  default     = "87.4.0"
}
