
terraform {
  backend "s3" {
    bucket = "your-unique-zalando-tfstate-prod"
    key    = "terraform.tfstate"
    region = "eu-north-1"
  }
}
