# alb.tf

# Application Load Balancer
resource "aws_lb" "app" {
  name               = "zalando-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]  # Use existing from security.tf

  subnets = [aws_subnet.public.id, aws_subnet.public_2.id] # Use existing public subnet

  tags = {
    Name        = "zalando-alb"
    Environment = "production"
  }
}

# Target Group for the ALB
resource "aws_lb_target_group" "app" {
  name     = "zalando-app-tg"
  port     = 3000  # Match our app SG port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200-399"
  }
  
  tags = {
    Name = "zalando-app-tg"
  }
}

# ALB Listener (port 80 -> target group)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
