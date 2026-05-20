
terraform {
  backend "s3" {
    bucket         = "devops-eks-demo-tfstate"
    key            = "environments/dev/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "devops-eks-demo-tflocks"
    encrypt        = true
  }
}

