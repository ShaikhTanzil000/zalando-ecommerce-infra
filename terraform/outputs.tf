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

output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}
