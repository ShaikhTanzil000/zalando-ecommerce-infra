# dynamodb.tf

# DynamoDB Table for application data
resource "aws_dynamodb_table" "app_data" {
  name         = "zalando-app-data"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ID"
  
  attribute {
    name = "ID"
    type = "S"
  }
  
  tags = {
    Name        = "zalando-app-data"
    Environment = "production"
  }
}
