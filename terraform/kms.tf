# phase6/kms.tf
# Why KMS? We need encryption keys to secure our logs at rest
# This ensures compliance with security best practices and regulatory requirements

# KMS key for CloudTrail logs encryption
# CloudTrail contains sensitive API activity data that must be encrypted
resource "aws_kms_key" "cloudtrail_key" {
  description             = "KMS key for encrypting CloudTrail logs"
  deletion_window_in_days = 7                    # Minimum deletion window for safety
  enable_key_rotation     = true                 # Automatic key rotation for security
  
  tags = {
    Name        = "zalando-cloudtrail-key"
    Environment = "production"
    Phase       = "6"
  }
}

# Create an alias for easier key reference in policies and console
resource "aws_kms_alias" "cloudtrail_key_alias" {
  name          = "alias/zalando-cloudtrail-key"
  target_key_id = aws_kms_key.cloudtrail_key.key_id
}

# KMS key for CloudWatch Logs encryption
# Application logs may contain sensitive information and should be encrypted
resource "aws_kms_key" "logs_key" {
  description             = "KMS key for CloudWatch Logs"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = {
    Name        = "zalando-logs-key"
    Environment = "production"
    Phase       = "6"
  }
}



#Adding this as were facing error with cloudtrail related to kms


# KMS key policy for CloudWatch Logs encryption key
resource "aws_kms_key_policy" "logs_key_policy" {
  key_id = aws_kms_key.logs_key.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow root account full access to manage the key
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        # Allow CloudWatch Logs service to use the key for encrypting logs
        Sid    = "Allow CloudWatch Logs usage"
        Effect = "Allow"
        Principal = {
          Service = "logs.eu-north-1.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}


############
resource "aws_kms_alias" "logs_key_alias" {
  name          = "alias/zalando-logs-key"
  target_key_id = aws_kms_key.logs_key.key_id
}

# KMS key policy specifically for CloudTrail service access
# CloudTrail needs specific permissions to use the KMS key for encryption
resource "aws_kms_key_policy" "cloudtrail_key_policy" {
  key_id = aws_kms_key.cloudtrail_key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow root account full access to manage the key
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        # Allow CloudTrail service to encrypt logs using this key
        Sid    = "Allow CloudTrail to encrypt logs"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey",    # Needed to encrypt individual log files
          "kms:DescribeKey"         # Needed to verify key details
        ]
        Resource = "*"
      }
    ]
  })
}
