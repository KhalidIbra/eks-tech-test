
terraform {
  backend "s3" {
    bucket         = "boba-tech-demo-tfstate"
    key            = "environments/dev/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "boba-tech-demo-tflocks"
    encrypt        = true
  }
}

