# iam.tf - Complete IAM configuration for bastion and application layers with explicit self-policy permissions
#=======================================================================================================
# Data source to retrieve AWS account ID
data "aws_caller_identity" "current" {}

# APPLICATION EC2 ROLE (for app instances in ASG)
#=======================================================================================================
# EC2 IAM Role for Application Layer
resource "aws_iam_role" "ec2_role" {
  name = "zalando-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = {
    Name        = "zalando-ec2-role"
    Purpose     = "Application runtime permissions"
    Environment = "production"
  }
}

# Attach AWS-managed policies to EC2 role
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "ec2_cw" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
resource "aws_iam_role_policy_attachment" "ec2_dynamo" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}
resource "aws_iam_role_policy_attachment" "ec2_elasticache" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElastiCacheFullAccess"
}

# Instance Profile for Application EC2 instances
resource "aws_iam_instance_profile" "app_profile" {
  name = "zalando-app-profile"
  role = aws_iam_role.ec2_role.name
  tags = {
    Name        = "zalando-app-instance-profile"
    Purpose     = "Application EC2 instances"
    Environment = "production"
  }
}

#=======================================================================================================
# BASTION HOST ROLE (for Terraform deployment and admin access)
#=======================================================================================================
# IAM Role for Bastion Host (Enhanced for Terraform deployment)
resource "aws_iam_role" "bastion_role" {
  name = "bastion-role-terraform-runner"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = {
    Name        = "bastion-terraform-role"
    Purpose     = "Infrastructure deployment via Terraform"
    Environment = "production"
  }
}

# Core Systems Manager permissions for bastion access
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch permissions for logging and monitoring
resource "aws_iam_role_policy_attachment" "bastion_cloudwatch" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# EC2 permissions for Terraform operations
resource "aws_iam_role_policy_attachment" "bastion_ec2" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# VPC permissions for networking
resource "aws_iam_role_policy_attachment" "bastion_vpc" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

# RDS permissions for database management
resource "aws_iam_role_policy_attachment" "bastion_rds" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

# ElastiCache permissions
resource "aws_iam_role_policy_attachment" "bastion_elasticache_mgmt" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElastiCacheFullAccess"
}

# DynamoDB permissions
resource "aws_iam_role_policy_attachment" "bastion_dynamodb" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# ELB permissions for load balancers
resource "aws_iam_role_policy_attachment" "bastion_elb" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

# Route 53 permissions for DNS
resource "aws_iam_role_policy_attachment" "bastion_route53" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

# S3 permissions for backend and static assets
resource "aws_iam_role_policy_attachment" "bastion_s3" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# CloudTrail permissions
resource "aws_iam_role_policy_attachment" "bastion_cloudtrail" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# Custom IAM policy for role management and passing roles with explicit resource ARNs
resource "aws_iam_role_policy" "bastion_iam_management" {
  name = "bastion-iam-management-policy"
  role = aws_iam_role.bastion_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # IAM permissions needed to list/read policies on bastion and app roles
          "iam:ListRolePolicies",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:GetPolicy",
          "iam:GetPolicyVersion"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          # Core IAM role management
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateRole",
          "iam:GetRole",
          "iam:ListRoles",

          # Instance profile operations
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:ListInstanceProfiles",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",

          # Policy attachment and role passing
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PassRole",

          # Additional AWS services
          "sns:*",
          "acm:*",
          "kms:*",
          "budgets:*",
          "config:*",
          "cloudtrail:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance profile for bastion host
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion-terraform-profile"
  role = aws_iam_role.bastion_role.name
  tags = {
    Name        = "bastion-instance-profile"
    Purpose     = "Bastion host for Terraform deployment"
    Environment = "production"
  }
}

#=======================================================================================================
# SHARED RESOURCES (SNS for alerts)
#=======================================================================================================
# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "zalando-alerts"
  tags = {
    Name        = "ZalandoAlertsTopic"
    Environment = "production"
  }
}

# SNS Email Subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

#=======================================================================================================
# OUTPUTS
#=======================================================================================================
output "bastion_role_arn" {
  description = "ARN of the bastion IAM role"
  value       = aws_iam_role.bastion_role.arn
}

output "bastion_instance_profile_name" {
  description = "Name of the bastion instance profile"
  value       = aws_iam_instance_profile.bastion_profile.name
}

output "app_role_arn" {
  description = "ARN of the application EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "app_instance_profile_name" {
  description = "Name of the application instance profile"
  value       = aws_iam_instance_profile.app_profile.name
}

