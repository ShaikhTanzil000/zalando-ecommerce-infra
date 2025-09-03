# rds.tf

# RDS DB Subnet Group (places RDS in the private subnets)
resource "aws_db_subnet_group" "zalando" {
  name       = "zalando-db-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_2.id]  # Use existing private subnet from Phase 2
  description = "Subnet group for Zalando RDS instances"
  
  tags = {
    Name = "zalando-db-subnet-group"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  allocated_storage      = 20
  engine                = "postgres"
  engine_version        = "13.7"
  instance_class        = "db.t3.micro"
  db_name               = var.db_name
  username              = var.db_username
  password              = var.db_password
  port                  = 5432
  storage_type          = "gp2"
  skip_final_snapshot   = true
  publicly_accessible   = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]  # Use existing from security.tf
  db_subnet_group_name   = aws_db_subnet_group.zalando.name

  tags = {
    Name        = "zalando-rds"
    Environment = "production"
  }
}
