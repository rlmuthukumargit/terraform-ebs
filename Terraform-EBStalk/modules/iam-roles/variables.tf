################################################################################
# IAM Roles Module - Variables
################################################################################

variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, qa, prod)"
  type        = string
}
