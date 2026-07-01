output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.this.zone_id
}

output "name_servers" {
  description = "Name servers for the hosted zone — delegate these at your registrar"
  value       = aws_route53_zone.this.name_servers
}

output "certificate_arn" {
  description = "ARN of the validated ACM certificate"
  value       = aws_acm_certificate_validation.this.certificate_arn
}
