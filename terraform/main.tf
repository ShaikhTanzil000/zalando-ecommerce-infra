provider "aws" {
  region = "eu-north-1"
}

resource "aws_s3_bucket" "tfstate" {
  bucket = "your-unique-zalando-tfstate-prod"  # Change to a globally unique name!
}


resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
