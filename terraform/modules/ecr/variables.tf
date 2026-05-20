variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "Tag mutability: MUTABLE or IMMUTABLE. Immutable is recommended."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "untagged_image_retention_days" {
  description = "Days to retain untagged images before lifecycle policy removes them"
  type        = number
  default     = 7
}

variable "max_tagged_image_count" {
  description = "Maximum number of tagged images to retain"
  type        = number
  default     = 30
}

variable "force_delete" {
  description = "Allow deletion of the repo even if it contains images. Useful for dev, dangerous for prod."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the repository"
  type        = map(string)
  default     = {}
}