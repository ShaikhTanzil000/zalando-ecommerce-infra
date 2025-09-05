# rds.tf - Fixed version with comments
# RDS configuration with proper multi-AZ subnet group

# RDS DB Subnet Group - FIXED VERSION
resource "aws_db_subnet_group" "zalando" {
  name       = "zalando-db-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_2.id]  
  description = "Subnet group for Zalando RDS instances"
  
  # IMPORTANT: This resource depends on both private subnets existing in DIFFERENT AZs
  # The subnets must be created first with proper AZ configuration:
  # - aws_subnet.private should be in eu-north-1a (availability_zones[0])
  # - aws_subnet.private_2 should be in eu-north-1b (availability_zones[1])
  depends_on = [
    aws_subnet.private,
    aws_subnet.private_2
  ]
  
  tags = {
    Name = "zalando-db-subnet-group"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  allocated_storage      = 20
  engine                = "postgres"
  engine_version        = "13.22"
  instance_class        = "db.t3.micro"
  db_name               = var.db_name
  username              = var.db_username
  password              = var.db_password
  port                  = 5432
  storage_type          = "gp2"
  skip_final_snapshot   = true
  publicly_accessible   = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.zalando.name
  
  tags = {
    Name        = "zalando-rds"
    Environment = "production"
  }
}

# CHANGES MADE:
# 1. ADDED explicit depends_on to ensure both private subnets are created before the DB subnet group
# 2. ADDED comments explaining the AZ requirement - both subnets must be in different AZs
# 3. The actual fix is in network.tf where private subnets must use different availability_zones:
#    - aws_subnet.private uses var.availability_zones[0] (eu-north-1a)  
#    - aws_subnet.private_2 uses var.availability_zones[1] (eu-north-1b)
# 4. The error "Current AZ coverage: eu-north-1b" suggests both subnets were in same AZ
#    This is fixed by ensuring variable.tf has: availability_zones = ["eu-north-1a", "eu-north-1b"]
#    And network.tf uses different indexes for each subnet's availability_zone
