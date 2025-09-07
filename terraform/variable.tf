variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-north-1"
}

variable "availability_zone" {
  description = "Availability Zone for subnets"
  type        = list(string)
  default     = ["eu-north-1a", "eu-north-1b"]     # ← adjust as needed
}


variable "state_bucket_name" {
  description = "Terraform state S3 bucket"
  type        = string
  default     = "your-unique-zalando-tfstate-prod"
}

variable "trusted_admin_ip" {
  description = "Your admin IP for SSH"
  type        = string
  default     = "103.132.31.123/32"  # Change to your public IP
}


variable "admin_public_key" {
  description = "SSH public key for bastion admin"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.4.0/24"]
}

# *********************Phase 3****************           Add to existing variables.tf
variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "zalando_admin"  #Chaged from Admin
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "zalando_db"
}

# Add these missing variables to your existing variable.tf

variable "domain_name" {
  description = "Domain name for DNS and certificates (e.g., example.com)"
  type        = string
  default     = "example.com"  # Change to your actual domain
}

variable "db_password" {
  description = "RDS master password (keep sensitive)"
  type        = string
  sensitive   = true
  # No default - must be provided via CLI or tfvars for security
}

variable "alert_email" {
  description = "Email address for CloudWatch alarms and notifications"
  type        = string
  default     = "admin@example.com"  # Change to your email
}

#----------------Phase-4---------------------

# Add these variables to your existing variables.tf
variable "ssh_pub_key" {
  description = "SSH public key for EC2 access"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsIQBwtX98sPyhE65m0a0+DT9bvniTdDutKL+OLRr7zXUt0pUzcu45mcN1YHzl69C88g5G+fKrIhKM2ivWLF8GWx3u3xEbDkFJgLNvidFmGzxyk+UuJO30nk8wAE1yS27bKsoPh4XQ6INzYLRxf4VAMvzMqruS55c3OWdLL55CCiT0eYW4rFurmgFo1C++hEe12uE6NIOCa+dZXuHhp3Bw4OTL0rp/GF3MdivOCcHSHpva28rgBvI4wtuKwZmc06isZRyFR1pcb/mkFJ1aBFxTuvx19Y5vGgD/y8Auc4WWoy2PRlmy/0XWjDmv/Oy+ZDSE59NtQvN1IimguO5zhNPZ"  # Replace with your actual key
}

variable "instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t3.micro"
}

