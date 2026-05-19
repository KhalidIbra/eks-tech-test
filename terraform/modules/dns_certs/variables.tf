variable "domain_name" {
  description = "Primary domain name for the certificate (e.g. example.com)"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional SANs for the cert (e.g. [\"*.example.com\"])"
  type        = list(string)
  default     = []
}

variable "create_route53_zone" {
  description = "Whether to create the Route53 hosted zone. Set false if it already exists."
  type        = bool
  default     = false
}

variable "hosted_zone_id" {
  description = "Existing Route53 hosted zone ID. Required if create_route53_zone is false."
  type        = string
  default     = null
}

variable "validation_method" {
  description = "Cert validation method. DNS is strongly recommended."
  type        = string
  default     = "DNS"

  validation {
    condition     = contains(["DNS", "EMAIL"], var.validation_method)
    error_message = "validation_method must be either DNS or EMAIL."
  }
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}