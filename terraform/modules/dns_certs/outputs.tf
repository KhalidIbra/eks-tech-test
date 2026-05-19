output "certificate_arn" {
  description = "ARN of the issued ACM certificate"
  value = var.validation_method == "DNS" ? (
    aws_acm_certificate_validation.this[0].certificate_arn
  ) : aws_acm_certificate.this.arn
}

output "certificate_domain" {
  description = "Primary domain name of the certificate"
  value       = aws_acm_certificate.this.domain_name
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID (created or referenced)"
  value       = local.zone_id
}

output "hosted_zone_name_servers" {
  description = "Name servers for the hosted zone (only set if zone was created)"
  value       = var.create_route53_zone ? aws_route53_zone.this[0].name_servers : null
}