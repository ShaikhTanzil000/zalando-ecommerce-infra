terraform {
  backend "s3" {
    bucket = "your-unique-zalando-tfstate-prod"  # Use your actual S3 bucket name
    key    = "terraform.tfstate"                 # File name/path in your S3 bucket
    region = "eu-north-1"                        # Same AWS region as your bucket
  }
}
