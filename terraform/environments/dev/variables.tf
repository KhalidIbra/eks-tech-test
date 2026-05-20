variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name used in resource naming and tagging"
  type        = string
  default     = "boba-tech-test"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "domain_name" {
  description = "Domain name for the public endpoint (e.g. dev.example.com)"
  type        = string
}

variable "hosted_zone_id" {
  description = "Existing Route53 hosted zone ID"
  type        = string
}



variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.29"
}