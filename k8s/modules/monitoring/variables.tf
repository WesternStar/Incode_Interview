variable "monitoring_namespace" {
  description = "Namespace for the kube-prometheus-stack (Prometheus, Grafana, Alertmanager) and YACE"
  type        = string
  default     = "monitoring"
}

variable "grafana_subdomain" {
  description = "Subdomain for the Grafana Ingress (e.g. 'grafana' -> grafana.example.com)"
  type        = string
  default     = "grafana"
}

variable "domain_name" {
  description = "Root domain used for the Grafana Ingress"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the validated ACM certificate used for the Grafana Ingress"
  type        = string
}

variable "kube_prometheus_stack_chart_version" {
  description = "Version of the prometheus-community/kube-prometheus-stack Helm chart"
  type        = string
  default     = "87.4.0"
}

variable "yace_chart_version" {
  description = "Version of the nerdswords/yet-another-cloudwatch-exporter Helm chart"
  type        = string
  default     = "0.38.0"
}

variable "aws_region" {
  description = "AWS region YACE polls CloudWatch in"
  type        = string
  default     = "us-east-1"
}

variable "yace_role_arn" {
  description = "IAM role ARN for Yet Another CloudWatch Exporter (YACE)"
  type        = string
}
