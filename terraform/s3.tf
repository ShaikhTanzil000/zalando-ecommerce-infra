# s3.tf - Static website hosting bucket
# S3 bucket for static website content (CSS, JS, images, HTML files)
resource "aws_s3_bucket" "static_site" {
  bucket = "zalando-static-site-${var.domain_name}-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "zalando-static-site"
    Environment = "production"
    Purpose     = "Static website hosting"
  }
}

# Generate random suffix to ensure bucket name uniqueness globally
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Configure bucket for static website hosting
resource "aws_s3_bucket_website_configuration" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"  # Default page when accessing root
  }

  error_document {
    key = "error.html"     # Custom 404 error page
  }
}

# Block all public access initially (CloudFront will access via OAI)
resource "aws_s3_bucket_public_access_block" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  block_public_acls       = true   # Block public ACLs for security
  block_public_policy     = true   # Block public bucket policies
  ignore_public_acls      = true   # Ignore any public ACLs
  restrict_public_buckets = true   # Restrict public bucket policies
}

# Server-side encryption for stored content
resource "aws_s3_bucket_server_side_encryption_configuration" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # Encrypt files at rest
    }
  }
}

# Versioning for content rollbacks if needed
resource "aws_s3_bucket_versioning" "static_site" {
  bucket = aws_s3_bucket.static_site.id
  versioning_configuration {
    status = "Enabled"  # Keep multiple versions of files
  }
}

# Lifecycle policy to manage old versions (cost optimization)
resource "aws_s3_bucket_lifecycle_configuration" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  rule {
    id     = "delete_old_versions"
    status = "Enabled"

    filter {
      prefix = ""  # Apply to all objects
    }

    noncurrent_version_expiration {
      noncurrent_days = 30  # Delete old versions after 30 days
    }
  }
}

# Bucket policy to allow CloudFront OAI access only
resource "aws_s3_bucket_policy" "static_site" {
  bucket = aws_s3_bucket.static_site.id
  
  # This policy allows ONLY CloudFront to access the bucket content
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOAI"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.s3_oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_site.arn}/*"
      }
    ]
  })
}


