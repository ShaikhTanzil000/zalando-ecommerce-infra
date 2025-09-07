# outputs.tf

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}

output "bastion_sg_id" {
  description = "Bastion security group ID"
  value       = aws_security_group.bastion_sg.id
}

output "alb_sg_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb_sg.id
}

output "app_sg_id" {
  description = "App server security group ID"
  value       = aws_security_group.app_sg.id
}

output "rds_sg_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds_sg.id
}

output "redis_sg_id" {
  description = "Redis security group ID"
  value       = aws_security_group.redis_sg.id
}

output "ec2_instance_profile" {
  description = "EC2 instance profile name"
  value       = aws_iam_instance_profile.app_profile.name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}


# Add to existing outputs.tf
output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.app_data.name
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.app.dns_name
}

#ROUTE53

output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       =  data.aws_route53_zone.main.zone_id
}


#Update of Output file for Phase 4

# Add these outputs to your existing outputs.tf

output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.app_asg.name
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.app_lt.id
}

output "app_security_group_id" {
  description = "Application Security Group ID"
  value       = aws_security_group.app_sg.id
}

#Update of Phase 5

# outputs.tf - Add these Phase 5 outputs to your existing file

# S3 bucket information
output "static_bucket_name" {
  description = "S3 bucket name for static site content"
  value       = aws_s3_bucket.static_site.bucket
}

output "static_bucket_website_endpoint" {
  description = "S3 bucket website endpoint"
  value       = aws_s3_bucket_website_configuration.static_site.website_endpoint
}

# CloudFront distribution information
output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = aws_cloudfront_distribution.cdn.id
}

# SSL certificate information
output "ssl_certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.site_cert.arn
}

# DNS information
output "static_site_url" {
  description = "Static site URL"
  value       = "https://static.${var.domain_name}"
}

output "main_site_url" {
  description = "Main application URL"
  value       = "https://www.${var.domain_name}"
}

