variable "domain_name" {
  description = "Root domain name for the Route 53 hosted zone and ACM certificate (e.g. example.com)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the hosted zone and certificate"
  type        = map(string)
  default     = {}
}
