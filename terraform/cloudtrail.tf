# phase6/cloudtrail.tf
# Why CloudTrail? It provides complete audit trail of all AWS API calls
# Essential for security monitoring, compliance, and forensic analysis

# Generate random suffix to ensure S3 bucket names are globally unique
# S3 bucket names must be globally unique across all AWS accounts
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false    # No special characters for S3 compatibility
  upper   = false    # Lowercase only for consistency
}

# S3 bucket to store CloudTrail logs
# CloudTrail requires an S3 bucket as the destination for log files
resource "aws_s3_bucket" "trail_bucket" {
  bucket        = "zalando-cloudtrail-logs-${random_string.bucket_suffix.result}"
  force_destroy = true    # Allow Terraform to delete bucket with contents (dev/test only)

  tags = {
    Name        = "zalando-cloudtrail-bucket"
    Environment = "production"
    Phase       = "6"
  }
}

# Enable versioning on the CloudTrail bucket
# Versioning protects against accidental deletion and provides audit history
resource "aws_s3_bucket_versioning" "trail_bucket_versioning" {
  bucket = aws_s3_bucket.trail_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configure server-side encryption for the CloudTrail bucket
# Encrypts all objects stored in the bucket using our KMS key
resource "aws_s3_bucket_server_side_encryption_configuration" "trail_bucket_encryption" {
  bucket = aws_s3_bucket.trail_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"                           # Use KMS encryption
      kms_master_key_id = aws_kms_key.cloudtrail_key.arn     # Use our custom key
    }
  }
}

# Block all public access to the CloudTrail bucket
# CloudTrail logs should never be publicly accessible for security
resource "aws_s3_bucket_public_access_block" "trail_bucket_pab" {
  bucket = aws_s3_bucket.trail_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy to allow CloudTrail service to write logs
# CloudTrail service needs specific permissions to deliver logs to S3
resource "aws_s3_bucket_policy" "trail_bucket_policy" {
  bucket = aws_s3_bucket.trail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow CloudTrail to check bucket ACL (required for setup)
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.trail_bucket.arn
      },
      {
        # Allow CloudTrail to write log files to the bucket
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.trail_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"    # Ensure bucket owner maintains control
          }
        }
      }
    ]
  })
}

# Main CloudTrail resource for comprehensive API logging
resource "aws_cloudtrail" "zalando_trail" {
  name                          = "zalando-trail"
  s3_bucket_name                = aws_s3_bucket.trail_bucket.id
  s3_key_prefix                 = "zalando-logs"                    # Organize logs with prefix
  include_global_service_events = true                             # Include global services (IAM, etc.)
  is_multi_region_trail         = true                             # Monitor all AWS regions
  is_organization_trail         = false                            # Single account trail
  enable_log_file_validation    = true                             # Enable integrity validation
  kms_key_id                    = aws_kms_key.cloudtrail_key.arn   # Encrypt with our KMS key

  # Configure event selectors to capture specific data events
  event_selector {
    read_write_type                 = "All"                        # Capture read and write events
    include_management_events       = true                         # Include management API calls
    exclude_management_event_sources = []                          # Don't exclude any sources

    # Monitor S3 object-level events for our static bucket
    # This provides detailed access logging for our static content


##############################################################################################################


#Temporary commenting the below out to run S3.tf 

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.static_site.arn}/*"]
    }
  }

  tags = {
    Name        = "zalando-cloudtrail"
    Environment = "production"
    Phase       = "6"
  }


  # Ensure proper dependencies are created before CloudTrail
  depends_on = [
    aws_s3_bucket_policy.trail_bucket_policy,
    aws_kms_key_policy.cloudtrail_key_policy
  ]

}

