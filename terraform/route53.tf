# route53.tf

# Route 53 hosted zone
resource "aws_route53_zone" "main" {
  name = var.domain_name
  
  tags = {
    Name = "zalando-zone"
  }
}

# Alias record for root domain pointing to ALB
resource "aws_route53_record" "alb_alias" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  
  alias {
    name                   = aws_lb.app.dns_name
    zone_id                = aws_lb.app.zone_id
    evaluate_target_health = true
  }
}
