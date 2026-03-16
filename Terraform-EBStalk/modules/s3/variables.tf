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

variable "manage_artifact_object" {
  description = "Whether Terraform should manage the application artifact S3 object. Set to false if using external CI/CD tool to upload."
  type        = bool
  default     = true
}
