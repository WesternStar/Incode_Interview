resource "aws_route53_zone" "this" {
  name = var.domain_name

  tags = merge(var.tags, { Name = var.domain_name })
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, { Name = var.domain_name })
}

resource "aws_route53_record" "cert_validation" {
  # A wildcard SAN shares the same validation CNAME as its base domain, so
  # domain_validation_options can contain multiple entries with identical
  # resource_record_name/value. Group by name and take one per group to
  # avoid creating (or trying to create) the same record twice.
  for_each = {
    for name, dvos in {
      for dvo in aws_acm_certificate.this.domain_validation_options : dvo.resource_record_name => dvo...
      } : name => {
      name   = dvos[0].resource_record_name
      type   = dvos[0].resource_record_type
      record = dvos[0].resource_record_value
    }
  }

  zone_id = aws_route53_zone.this.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}
