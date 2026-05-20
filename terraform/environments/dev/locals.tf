locals {
  common_tags = {
    project     = var.project_name
    environment = var.environment
    managed-by  = "terraform"
    repository  = "devops-eks-demo"
  }

  azs = ["${var.region}a", "${var.region}b", "${var.region}c"]
}