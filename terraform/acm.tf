# acm.tf - SSL/TLS certificates for HTTPS
# IMPORTANT: ACM certificates for CloudFront must be created in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"                                 # CloudFront requires certificates in this region
}

# Request SSL certificate for our domain and subdomain
resource "aws_acm_certificate" "site_cert" {
  provider                  = aws.us_east_1            # Must use us-east-1 for CloudFront
  domain_name               = var.domain_name          # Main domain (example.com)
  subject_alternative_names = [                        # Additional domains covered by certificate
    "www.${var.domain_name}",                         # www subdomain
    "static.${var.domain_name}"                       # static subdomain for CDN
  ]
  validation_method = "DNS"                            # Use DNS validation (automatic)

  lifecycle {
    create_before_destroy = true                       # Ensure no downtime during certificate renewal
  }

  tags = {
    Name        = "zalando-ssl-cert"
    Environment = "production"
    Purpose     = "HTTPS encryption"
  }
}

# Create DNS validation records in Route 53
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id              # Reference to Route 53 zone from Phase 3
  name    = each.value.name
  type    = each.value.type
  ttl     = 60                                         # Short TTL for validation
  records = [each.value.record]

  allow_overwrite = true                               # Allow overwriting existing validation records
}

# Wait for certificate validation to complete
resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.site_cert.arn
  validation_record_fqdns = [for v in aws_route53_record.cert_validation : v.fqdn]

  timeouts {
    create = "10m"                                     # Wait up to 10 minutes for validation
  }
}
