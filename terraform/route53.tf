# route53.tf

# Route 53 hosted zone
#resource "aws_route53_zone" "main" {
#  name = var.domain_name
  
#  tags = {
#    Name = "zalando-zone"
#  }
#}

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# Alias record for root domain pointing to ALB
resource "aws_route53_record" "alb_alias" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  
  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}


#Update of Phase 5
# route53.tf - Add these DNS records to your existing route53.tf file

# DNS record for static content subdomain -> CloudFront
resource "aws_route53_record" "cdn_alias" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "static.${var.domain_name}"                # static.example.com
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name      # CloudFront distribution URL
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id   # CloudFront hosted zone
    evaluate_target_health = true
  }
}

# DNS record for www subdomain -> ALB (continuing from Phase 3)
resource "aws_route53_record" "www_alias" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${var.domain_name}"                   # www.example.com
  type    = "A"

  alias {
    name                   = aws_lb.app.dns_name       # ALB from Phase 3
    zone_id                = aws_lb.app.zone_id        # ALB hosted zone
    evaluate_target_health = true
  }
}

# AAAA record for IPv6 support on static subdomain
resource "aws_route53_record" "cdn_alias_ipv6" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "static.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = true
  }
}

