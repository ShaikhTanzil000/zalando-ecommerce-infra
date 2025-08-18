variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-north-1"
}

variable "availability_zone" {
  description = "Availability Zone for subnets"
  type        = string
  default     = "eu-north-1a"     # ← adjust as needed
}


variable "state_bucket_name" {
  description = "Terraform state S3 bucket"
  type        = string
  default     = "your-unique-zalando-tfstate-prod"
}

variable "trusted_admin_ip" {
  description = "Your admin IP for SSH"
  type        = string
  default     = "103.176.156.231/32"  # Change to your public IP
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
  default     = ["10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}
