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

variable "demo_app_image" {
  description = "Container image for the demo application"
  type        = string
  default     = "nginxdemos/hello"
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
  description = "Subdomain for the demo app (e.g. 'app' → app.example.com)"
  type        = string
  default     = "app"
}
