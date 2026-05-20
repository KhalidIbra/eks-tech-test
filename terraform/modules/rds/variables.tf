variable "identifier" {
  description = "RDS instance identifier"
  type        = string
  default = "boba-tech-test-dev"
}

variable "engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper bound for storage autoscaling. Set equal to allocated_storage to disable."
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Name of the initial database created"
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "Master DB username"
  type        = string
  default     = "admin"
}

variable "multi_az" {
  description = "Whether to deploy in Multi-AZ. Required for HA."
  type        = bool
  default     = true
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group (must span at least 2 AZs)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "RDS requires at least 2 subnets in different AZs."
  }
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to the database (typically the EKS node SG)"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID where the security group will live"
  type        = string
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the database"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on deletion. Set true only for dev/throwaway."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}