# Data source to get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Launch Template for application server instances
resource "aws_launch_template" "app_lt" {
  name_prefix   = "zalando-app-"
  description   = "Launch template for zalando application servers"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.app_key.key_name

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # User data script to bootstrap the application
  user_data = base64encode(file("${path.module}/user_data.sh"))

  # Instance profile for AWS permissions
  iam_instance_profile {
    name = aws_iam_instance_profile.app_profile.name
  }

  # EBS optimization for better I/O performance
  ebs_optimized = true

  # Enable detailed monitoring
  monitoring {
    enabled = true
  }

  # Instance metadata service v2 (security best practice)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 1
  }

  # Block device mapping for root volume
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type          = "gp3"
      delete_on_termination = true
      encrypted            = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "zalando-app-server"
      Environment = "production"
      Role        = "application-server"
    }
  }
}
