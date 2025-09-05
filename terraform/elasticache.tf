# elasticache.tf - Fixed version with comments

# ElastiCache Subnet Group for Redis
resource "aws_elasticache_subnet_group" "redis" {
  name       = "zalando-redis-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_2.id]  
  description = "Subnet group for Zalando Redis cluster"
}

# ElastiCache Redis Cluster - FIXED VERSION
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "zalando-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"  # FIXED: Removed .x suffix - eu-north-1 uses "default.redis7" not "default.redis7.x"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis_sg.id]
  
  tags = {
    Name        = "zalando-redis"
    Environment = "production"
  }
}

# CHANGE MADE: 
# - Changed parameter_group_name from "default.redis7.x" to "default.redis7"
# - The .x suffix doesn't exist in eu-north-1 region's default parameter groups
# - This matches the redis7 engine family without the non-existent .x extension
