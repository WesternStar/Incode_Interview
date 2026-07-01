variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "Whether image tags can be overwritten (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Whether to scan images for vulnerabilities on push"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the repository"
  type        = map(string)
  default     = {}
}
