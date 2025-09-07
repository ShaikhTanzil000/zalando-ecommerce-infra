# SSH key pair for EC2 instances
resource "aws_key_pair" "app_key" {
  key_name   = "zalando-app-key"
  public_key = var.ssh_pub_key

  tags = {
    Name = "zalando-app-key"
  }
}
