# phase7/validation.tf
# Why automated validation? Ensures infrastructure is working correctly after deployment
# Catches configuration issues before they impact users

# Basic validation tests using null_resource with local-exec provisioner
# null_resource allows us to run arbitrary commands as part of Terraform deployment
resource "null_resource" "validation_tests" {
  # Run basic AWS CLI checks after deployment
  # These commands verify that all components are healthy and accessible
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      echo "=== Starting Deployment Validation ==="
      
      # Check ALB target health - ensures EC2 instances are registered and healthy
      echo "Checking ALB target health..."
      aws elbv2 describe-target-health \
        --target-group-arn ${aws_lb_target_group.app.arn} \
        --query 'TargetHealthDescriptions[].TargetHealth.State' \
        --output table
      
      # Check EC2 instances in ASG - verifies instances are running and properly tagged
      echo "Checking EC2 instances in ASG..."
      aws ec2 describe-instances \
        --filters "Name=tag:aws:autoscaling:groupName,Values=${aws_autoscaling_group.app_asg.name}" \
        --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress]' \
        --output table
      
      # Check ALB health - ensures load balancer is active and ready
      echo "Checking ALB health..."
      aws elbv2 describe-load-balancers \
        --load-balancer-arns ${aws_lb.app.arn} \
        --query 'LoadBalancers[].State' \
        --output table
      
      # Check RDS instance status - verifies database is available
      echo "Checking RDS instance status..."
      aws rds describe-db-instances \
        --db-instance-identifier ${aws_db_instance.postgres.identifier} \
        --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]' \
        --output table
      
      # Check CloudFront distribution status - ensures CDN is deployed
      echo "Checking CloudFront distribution status..."
      aws cloudfront get-distribution \
        --id ${aws_cloudfront_distribution.cdn.id} \
        --query 'Distribution.[Id,Status,DomainName]' \
        --output table
      
      # Check S3 bucket accessibility - verifies static content storage
      echo "Checking S3 bucket accessibility..."
      aws s3 ls s3://${aws_s3_bucket.static_bucket.bucket}/ --summarize
      
      echo "=== Validation Tests Complete ==="
    EOF
  }

  # Trigger re-validation when key resources change
  # This ensures validation runs whenever infrastructure is modified
  triggers = {
    alb_arn             = aws_lb.app.arn
    asg_name            = aws_autoscaling_group.app_asg.name
    target_group_arn    = aws_lb_target_group.app.arn
    rds_identifier      = aws_db_instance.postgres.identifier
    cloudfront_id       = aws_cloudfront_distribution.cdn.id
    static_bucket       = aws_s3_bucket.static_bucket.bucket
  }

  # Ensure all dependencies are created before validation
  depends_on = [
    aws_lb.app,
    aws_autoscaling_group.app_asg,
    aws_db_instance.postgres,
    aws_cloudfront_distribution.cdn
  ]
}

# Health check validation with retry logic
# More sophisticated validation that waits for services to be ready
resource "null_resource" "health_check_validation" {
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      echo "=== Health Check Validation ==="
      
      # Wait for ALB to be ready - ALBs take time to become active
      echo "Waiting for ALB to be active..."
      aws elbv2 wait load-balancer-available --load-balancer-arns ${aws_lb.app.arn}
      
      # Test ALB endpoint with retry logic
      ALB_DNS="${aws_lb.app.dns_name}"
      echo "Testing ALB endpoint: $ALB_DNS"
      
      # Basic HTTP health check with retries
      # Retries account for instances that might still be starting up
      for i in {1..5}; do
        echo "Attempt $i/5: Testing HTTP connection..."
        if curl -s -o /dev/null -w "%%{http_code}" "http://$ALB_DNS" | grep -q "200\|301\|302"; then
          echo "✓ ALB is responding"
          break
        else
          echo "⚠ ALB not ready, waiting 30 seconds..."
          sleep 30
        fi
      done
      
      # Test static site via CloudFront - ensures CDN is working
      CLOUDFRONT_DNS="${aws_cloudfront_distribution.cdn.domain_name}"
      echo "Testing CloudFront endpoint: $CLOUDFRONT_DNS"
      curl -s -o /dev/null -w "Status: %%{http_code}, Time: %%{time_total}s\n" "https://$CLOUDFRONT_DNS"
      
      echo "=== Health Check Validation Complete ==="
    EOF
  }

  depends_on = [
    null_resource.validation_tests,
    aws_cloudfront_distribution.cdn
  ]
}

# Load testing preparation
# Creates scripts and documentation for performance testing
resource "null_resource" "load_test_prep" {
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      echo "=== Load Test Preparation ==="
      
      # Create a comprehensive load test script
      # This script provides various load testing options for different scenarios
      cat > load_test.sh << 'EOL'
#!/bin/bash
ALB_DNS="${aws_lb.app.dns_name}"
CLOUDFRONT_DNS="${aws_cloudfront_distribution.cdn.domain_name}"

echo "Load testing ALB endpoint: $ALB_DNS"
echo "Run the following commands for load testing:"
echo ""
echo "# Basic load test with curl (run from bastion host):"
echo "for i in {1..100}; do curl -s http://$ALB_DNS > /dev/null && echo 'Request $i: OK' || echo 'Request $i: FAILED'; done"
echo ""
echo "# ApacheBench test (if available):"
echo "ab -n 1000 -c 10 http://$ALB_DNS/"
echo ""
echo "# CloudFront load test:"
echo "ab -n 500 -c 5 https://$CLOUDFRONT_DNS/"
echo ""
echo "# Monitor during load test:"
echo "aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name RequestCount --dimensions Name=LoadBalancer,Value=${aws_lb.app.arn_suffix} --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Sum"
EOL
      
      chmod +x load_test.sh
      echo "✓ Load test script created: load_test.sh"
      echo "=== Load Test Preparation Complete ==="
    EOF
  }

  depends_on = [null_resource.health_check_validation]
}
