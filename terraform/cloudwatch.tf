# phase6/cloudwatch.tf
# Why CloudWatch? Centralized logging and monitoring for operational visibility
# Essential for troubleshooting, performance monitoring, and alerting

# CloudWatch Log Group for application logs
# Centralizes application logs from EC2 instances for easy searching and analysis
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/zalando/app"                    # Hierarchical naming convention
  retention_in_days = 14                               # Control costs with reasonable retention
  kms_key_id        = aws_kms_key.logs_key.arn        # Encrypt logs at rest

  depends_on = [aws_kms_key_policy.logs_key_policy]

  tags = {
    Name        = "zalando-app-logs"
    Environment = "production"
    Phase       = "6"
  }
}

# Log stream within the application log group
# Provides structured way to organize logs (by instance, service, etc.)
resource "aws_cloudwatch_log_stream" "app_stream" {
  name           = "app-stream"
  log_group_name = aws_cloudwatch_log_group.app_logs.name
}

# CloudWatch Log Group for web server access logs
# Separate log group for HTTP access logs (nginx/apache logs)
resource "aws_cloudwatch_log_group" "web_logs" {
  name              = "/zalando/web"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.logs_key.arn

  depends_on = [aws_kms_key_policy.logs_key_policy]

  tags = {
    Name        = "zalando-web-logs"
    Environment = "production"
    Phase       = "6"
  }
}

resource "aws_cloudwatch_log_stream" "web_stream" {
  name           = "web-stream"
  log_group_name = aws_cloudwatch_log_group.web_logs.name
}

# CloudWatch Metric Alarm for high CPU utilization
# Monitors EC2 instances in Auto Scaling Group for resource exhaustion
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "zalando-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2                              # Require 2 consecutive breaches to avoid false positives
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300                            # 5-minute evaluation period
  statistic           = "Average"                      # Use average to smooth out spikes
  threshold           = 80                             # Alert when CPU > 80%
  alarm_description   = "This alarm monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]    # Send notification when alarm triggers
  ok_actions          = [aws_sns_topic.alerts.arn]    # Send notification when alarm clears
  treat_missing_data  = "notBreaching"                # Don't alarm if no data

  # Monitor all instances in our Auto Scaling Group
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  tags = {
    Name        = "zalando-high-cpu-alarm"
    Environment = "production"
    Phase       = "6"
  }
}

# CloudWatch Metric Alarm for ALB 5xx errors
# Monitors application health by tracking server errors
resource "aws_cloudwatch_metric_alarm" "high_5xx" {
  alarm_name          = "zalando-high-http-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"    # Counts 5xx responses from targets
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"                          # Sum all 5xx errors in period
  threshold           = 5                              # Alert when >5 errors in 5 minutes
  alarm_description   = "This alarm monitors ALB 5xx errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"                # No errors = good

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix               # Monitor our specific ALB
  }

  tags = {
    Name        = "zalando-5xx-errors-alarm"
    Environment = "production"
    Phase       = "6"
  }
}

# CloudWatch Metric Alarm for ALB response time
# Monitors application performance by tracking response latency
resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "zalando-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"           # Time for targets to respond
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"                      # Average response time
  threshold           = 5                              # Alert when avg response > 5 seconds
  alarm_description   = "This alarm monitors ALB response time"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
  }

  tags = {
    Name        = "zalando-response-time-alarm"
    Environment = "production"
    Phase       = "6"
  }
}

# CloudWatch Metric Alarm for RDS CPU utilization
# Monitors database performance to prevent database bottlenecks
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "zalando-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 75                             # Lower threshold for database (more sensitive)
  alarm_description   = "This alarm monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.identifier
  }

  tags = {
    Name        = "zalando-rds-cpu-alarm"
    Environment = "production"
    Phase       = "6"
  }
}

# CloudWatch Dashboard for visual monitoring
# Provides a single pane of glass for monitoring infrastructure health
resource "aws_cloudwatch_dashboard" "zalando_dashboard" {
  dashboard_name = "Zalando-App-Dashboard"

  # Dashboard configuration in JSON format
  dashboard_body = jsonencode({
    widgets = [
      {
        # ALB metrics widget - shows load balancer performance
        type   = "metric"
        x      = 0        # Position on dashboard
        y      = 0
        width  = 12       # Widget size
        height = 6

        properties = {
          metrics = [
            # Key ALB metrics to monitor
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.app.arn_suffix],           # Total requests
            [".", "HTTPCode_Target_2XX_Count", ".", "."],                                            # Successful responses
            [".", "HTTPCode_Target_5XX_Count", ".", "."],                                            # Server errors
            [".", "TargetResponseTime", ".", "."]                                                    # Response latency
          ]
          view    = "timeSeries"       # Show as time-series graph
          stacked = false              # Don't stack metrics
          region  = var.aws_region
          title   = "ALB Metrics"
          period  = 300                # 5-minute data points
        }
      },
      {
        # EC2 metrics widget - shows compute resource utilization
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.app_asg.name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "EC2 CPU Utilization"
          period  = 300
        }
      }
    ]
  })

#  tags = {
#    Name        = "zalando-dashboard"
#    Environment = "production"
#    Phase       = "6"
#  }
}
