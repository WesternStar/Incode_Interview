variable "app_namespace" {
  description = "Namespace to deploy the demo app into"
  type        = string
  default     = "default"
}

variable "demo_app_replicas" {
  description = "Number of replicas for the demo application"
  type        = number
  default     = 2
}

variable "ecr_repository_url" {
  description = "ECR repository URL the demo app image is pushed to"
  type        = string
}

variable "demo_app_image_tag" {
  description = "Tag to deploy from the ECR repo"
  type        = string
  default     = "latest"
}

variable "database_url" {
  description = "Full connection string the app connects to (postgres://user:pass@host:port/dbname) — app/main.go takes a single DATABASE_URL, not discrete host/port/etc."
  type        = string
  sensitive   = true
}

variable "app_subdomain" {
  description = "Subdomain for the demo app (e.g. 'music' -> music.example.com)"
  type        = string
  default     = "music"
}

variable "domain_name" {
  description = "Root domain used for the app Ingress"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the validated ACM certificate used for the app Ingress"
  type        = string
}
