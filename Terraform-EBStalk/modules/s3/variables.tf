################################################################################
# S3 Module — Variables
################################################################################

variable "resource_prefix" {
  description = "A naming prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "app_source_file" {
  description = "Path to the local application JAR/WAR artifact"
  type        = string
}

variable "app_s3_key" {
  description = "Destination object key inside the S3 bucket"
  type        = string
}
