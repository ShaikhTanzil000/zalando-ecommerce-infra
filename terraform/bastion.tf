# 1. Lookup the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


# 3. Import your SSH public key for admin access
resource "aws_key_pair" "admin_key" {
  key_name   = "admin-key"
  public_key = var.admin_public_key
}

# 4. EC2 instance definition for the bastion host
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.admin_key.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  user_data_base64 = base64encode(templatefile("${path.module}/bootstrap-bastion.sh", {
    terraform_version = "1.5.0"
    aws_region        =var.aws_region
  }))

  tags = {
    Name = "admin-bastion-host"
    Role = "administration"
  }
}
