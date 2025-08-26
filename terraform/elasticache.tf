# elasticache.tf

# ElastiCache Subnet Group for Redis
resource "aws_elasticache_subnet_group" "redis" {
  name       = "zalando-redis-subnet-group"
  subnet_ids = [aws_subnet.private.id]  # Use existing private subnet
  description = "Subnet group for Zalando Redis cluster"
}

# ElastiCache Redis Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "zalando-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis_sg.id]  # Use existing from security.tf
  
  tags = {
    Name        = "zalando-redis"
    Environment = "production"
  }
}
