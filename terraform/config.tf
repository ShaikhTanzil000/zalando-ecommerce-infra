# phase7/config.tf
# Why AWS Config? Provides continuous compliance monitoring and configuration drift detection
# Essential for maintaining security posture and regulatory compliance

# AWS Config Service Role
# Config service needs permissions to read resource configurations and write to S3
resource "aws_iam_role" "config_role" {
  name = "zalando-config-role"

  # Trust policy allowing Config service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "zalando-config-role"
    Environment = "production"
    Phase       = "7"
  }
}

# Attach AWS managed policy for Config service
# This policy provides necessary permissions for Config to function
resource "aws_iam_role_policy_attachment" "config_role_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

# S3 bucket for storing Config snapshots and history
# Config needs a place to store configuration snapshots and change history
resource "aws_s3_bucket" "config_bucket" {
  bucket        = "zalando-config-bucket-${random_string.bucket_suffix.result}"
  force_destroy = true    # Allow deletion for dev/test environments

  tags = {
    Name        = "zalando-config-bucket"
    Environment = "production"
    Phase       = "7"
  }
}

# S3 bucket policy for Config service
# Config service needs specific permissions to write configuration data
resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow Config to check bucket ACL
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config_bucket.arn
      },
      {
        # Allow Config to list bucket contents
        Sid    = "AWSConfigBucketExistenceCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.config_bucket.arn
      },
      {
        # Allow Config to write configuration snapshots and history
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# AWS Config Configuration Recorder
# This component actually records resource configurations and changes
resource "aws_config_configuration_recorder" "recorder" {
  name     = "zalando-recorder"
  role_arn = aws_iam_role.config_role.arn

  # Record all supported AWS resources in this account
  recording_group {
    all_supported = true    # Monitor all resource types that Config supports
  }

  # Must create delivery channel first
  depends_on = [aws_config_delivery_channel.channel]
}

# AWS Config Delivery Channel
# Defines where Config sends snapshots and configuration history
resource "aws_config_delivery_channel" "channel" {
  name           = "zalando-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.id
  s3_key_prefix  = "config"    # Organize Config data in S3
}

# AWS Config rule: CloudTrail enabled
# Ensures CloudTrail is enabled for audit logging
resource "aws_config_config_rule" "cloud_trail_enabled" {
  name = "zalando-cloud-trail-enabled"

  source {
    owner             = "AWS"                    # Use AWS managed rule
    source_identifier = "CLOUD_TRAIL_ENABLED"   # Specific rule identifier
  }

  tags = {
    Name        = "zalando-cloudtrail-rule"
    Environment = "production"
    Phase       = "7"
  }

  # Ensure recorder is active before creating rules
  depends_on = [aws_config_configuration_recorder.recorder]
}

# AWS Config rule: RDS storage encrypted
# Ensures all RDS instances have encryption enabled
resource "aws_config_config_rule" "rds_storage_encrypted" {
  name = "zalando-rds-storage-encrypted"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  tags = {
    Name        = "zalando-rds-encrypted-rule"
    Environment = "production"
    Phase       = "7"
  }

  depends_on = [aws_config_configuration_recorder.recorder]
}

# AWS Config rule: S3 bucket server side encryption enabled
# Ensures all S3 buckets have encryption configured
resource "aws_config_config_rule" "s3_bucket_server_side_encryption_enabled" {
  name = "zalando-s3-server-side-encryption-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  tags = {
    Name        = "zalando-s3-encryption-rule"
    Environment = "production"
    Phase       = "7"
  }

  depends_on = [aws_config_configuration_recorder.recorder]
}

# AWS Config rule: Security groups should not allow unrestricted SSH access
# Prevents security groups from allowing SSH (port 22) from 0.0.0.0/0
resource "aws_config_config_rule" "incoming_ssh_disabled" {
  name = "zalando-incoming-ssh-disabled"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  tags = {
    Name        = "zalando-ssh-rule"
    Environment = "production"
    Phase       = "7"
  }

  depends_on = [aws_config_configuration_recorder.recorder]
}

# AWS Config rule: ALB should redirect HTTP to HTTPS
# Ensures load balancers are configured for secure connections
resource "aws_config_config_rule" "alb_http_to_https_redirection_check" {
  name = "zalando-alb-http-to-https-redirection-check"

  source {
    owner             = "AWS"
    source_identifier = "ALB_HTTP_TO_HTTPS_REDIRECTION_CHECK"
  }

  tags = {
    Name        = "zalando-alb-https-rule"
    Environment = "production"
    Phase       = "7"
  }

  depends_on = [aws_config_configuration_recorder.recorder]
}
