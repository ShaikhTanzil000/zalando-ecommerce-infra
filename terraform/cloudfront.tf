# cloudfront.tf - CDN for global content delivery
# Origin Access Identity - allows CloudFront to access private S3 bucket
resource "aws_cloudfront_origin_access_identity" "s3_oai" {
  comment = "OAI for Zalando static site S3 bucket access"
}

# CloudFront Distribution - Global CDN for static content
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true                    # Enable the distribution
  is_ipv6_enabled     = true                   # Support IPv6 for better accessibility
  default_root_object = "index.html"           # Default file when accessing root URL
  price_class         = "PriceClass_100"       # Use only North America and Europe edge locations (cheaper)

  # Origin configuration - where CloudFront gets content from (our S3 bucket)
  origin {
    domain_name = aws_s3_bucket.static_site.bucket_regional_domain_name  # S3 bucket endpoint
    origin_id   = "S3-${aws_s3_bucket.static_site.bucket}"              # Unique identifier

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_oai.cloudfront_access_identity_path
    }
  }

  # Custom domain aliases (what users will type in browser)
  aliases = ["static.${var.domain_name}"]

  # Default cache behavior for all content
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]                    # Only cache GET and HEAD requests
    target_origin_id = "S3-${aws_s3_bucket.static_site.bucket}"
    compress         = true                               # Enable gzip compression

    forwarded_values {
      query_string = false                               # Don't forward query strings to S3
      headers      = []                                  # Don't forward custom headers

      cookies {
        forward = "none"                                 # Don't forward cookies for static content
      }
    }

    viewer_protocol_policy = "redirect-to-https"        # Force HTTPS for security
    min_ttl                = 0                          # Minimum cache time
    default_ttl            = 3600                       # Default cache time (1 hour)
    max_ttl                = 86400                      # Maximum cache time (24 hours)
  }

  # Cache behavior for CSS, JS, and image files (longer caching)
  ordered_cache_behavior {
    path_pattern     = "*.css"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.static_site.bucket}"
    compress         = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 86400                      # Cache CSS for 24 hours minimum
    default_ttl            = 86400
    max_ttl                = 31536000                   # Cache for up to 1 year
  }

  ordered_cache_behavior {
    path_pattern     = "*.js"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.static_site.bucket}"
    compress         = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 86400                      # Cache JavaScript for 24 hours
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  # Geographic restrictions (if needed)
  restrictions {
    geo_restriction {
      restriction_type = "none"                         # No geographic restrictions
    }
  }

  # SSL/TLS certificate configuration
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method       = "sni-only"              # Server Name Indication (cheaper option)
    minimum_protocol_version = "TLSv1.2_2021"         # Minimum TLS version for security
  }

  # Custom error pages
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/error.html"              # Custom 404 page
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/error.html"
    error_caching_min_ttl = 300
  }

  tags = {
    Name        = "zalando-cdn"
    Environment = "production"
    Purpose     = "Static content delivery"
  }
}
