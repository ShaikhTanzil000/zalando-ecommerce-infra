# Get private subnets (created in Phase 1-2)
#Commenting below out due to Error this was already done in security.tf but this duplicate this was created for Phase 4


# Security group for application servers
#resource "aws_security_group" "app_sg" {
#  name        = "zalando-app-sg"
#  description = "Security group for application servers"
#  vpc_id      = aws_vpc.main.id  # References your existing VPC

  # Allow HTTP traffic from ALB security group
#  ingress {
#    description     = "HTTP from ALB"
#    from_port       = 80
#    to_port         = 80
#    protocol        = "tcp"
#    security_groups = [aws_security_group.alb_sg.id]  # References ALB SG from Phase 3
#  }

  # Allow HTTPS traffic from ALB security group
#  ingress {
#    description     = "HTTPS from ALB"
#    from_port       = 443
#    to_port         = 443
#    protocol        = "tcp"
#    security_groups = [aws_security_group.alb_sg.id]
#  }

  # Allow SSH from bastion host
#  ingress {
#    description     = "SSH from bastion"
#    from_port       = 22
#    to_port         = 22
#    protocol        = "tcp"
#    security_groups = [aws_security_group.bastion_sg.id]  # References bastion SG
#  }

#  # Allow all outbound traffic
#  egress {
#    description = "All outbound traffic"
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }

#  tags = {
#    Name = "zalando-app-sg"
#  }
#}

# Auto Scaling Group for the application servers
resource "aws_autoscaling_group" "app_asg" {
  name                      = "zalando-app-asg"
  max_size                  = 5
  min_size                  = 2
  desired_capacity          = 3
  health_check_type         = "ELB"  # Use ALB health checks
  health_check_grace_period = 300
  force_delete              = true
  wait_for_capacity_timeout = "10m"

  # Use private subnets for security
  vpc_zone_identifier = [aws_subnet.private.id,
    aws_subnet.private_2.id]

  # Launch template configuration
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  # Target group attachment for ALB (references Phase 3 target group)
  target_group_arns = [aws_lb_target_group.app.arn]

  # Instance refresh configuration for rolling updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup       = 300
    }
    triggers = ["tag"]
  }

  # Tags that propagate to instances
  tag {
    key                 = "Name"
    value               = "zalando-app-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "production"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "application-server"
    propagate_at_launch = true
  }

  depends_on = [
    aws_lb_target_group.app,
    aws_launch_template.app_lt
  ]
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "zalando-scale-up"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "zalando-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}

# CloudWatch Alarms for Auto Scaling
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "zalando-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "zalando-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}
