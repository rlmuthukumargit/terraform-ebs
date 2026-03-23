################################################################################
# Root Module - Variable Declarations
# Values are supplied per-environment via environments/*.tfvars
################################################################################

# =============================================================================
# General
# =============================================================================
variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "resource_prefix" {
  description = "A naming prefix for all resources created by this Terraform configuration"
  type        = string
}

variable "aws_account_id" {
  description = "Target AWS account ID for this environment"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "Environment must be one of: dev, qa, prod."
  }
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}



# =============================================================================
# VPC / Networking
# =============================================================================
variable "vpc_id" {
  description = "ID of the existing VPC to use"
  type        = string
}

variable "subnet_ids" {
  description = "List of existing subnet IDs to use"
  type        = list(string)
}

# =============================================================================
# Security Groups
# =============================================================================
variable "alb_ingress_cidrs" {
  description = "CIDRs allowed to access the public ALB listener"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "alb_listener_port" {
  description = "ALB listener port"
  type        = number
  default     = 80
}

variable "app_port" {
  description = "Application port exposed by Elastic Beanstalk instances"
  type        = number
  default     = 80
}

# =============================================================================
# Elastic Beanstalk
# =============================================================================
variable "app_name" {
  description = "Elastic Beanstalk application name"
  type        = string
}

variable "solution_stack_name" {
  description = "EB platform / solution stack name"
  type        = string
  default     = "64bit Amazon Linux 2023 v4.10.0 running Corretto 21"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "min_instances" {
  description = "Minimum instances in ASG"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum instances in ASG"
  type        = number
  default     = 4
}

variable "root_volume_size" {
  description = "The size of the EBS root volume (in GB)"
  type        = number
  default     = 20
}

# =============================================================================
# S3 Application Source
# =============================================================================
variable "app_s3_bucket" {
  description = "S3 bucket containing the application JAR/WAR"
  type        = string
}

variable "app_s3_key" {
  description = "S3 key (path) for the application ZIP bundle"
  type        = string
  default     = ""
}

variable "app_local_path" {
  description = "Local path to the application ZIP file for automated upload"
  type        = string
  default     = "app.zip"
}

variable "app_version_label" {
  description = "Version label for the EB application version"
  type        = string
  default     = "v1"
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 30
}

# =============================================================================
# CloudWatch Alarms
# =============================================================================
variable "cpu_threshold" {
  description = "CPU utilization alarm threshold (%)"
  type        = number
  default     = 80
}

variable "latency_threshold" {
  description = "ALB target response time alarm threshold (seconds)"
  type        = number
  default     = 1.5
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the ALB target group for CloudWatch dimensions"
  type        = string
  default     = ""
}

variable "create_sns_topic" {
  description = "Create a new SNS topic for alarms (true) or use existing (false)"
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "ARN of existing SNS topic (required if create_sns_topic = false)"
  type        = string
  default     = ""
}

variable "alarm_email" {
  description = "Email for alarm notifications (leave empty to skip)"
  type        = string
  default     = ""
}

variable "eb_environment_name" {
  description = "Optional explicit Elastic Beanstalk environment name"
  type        = string
  default     = ""
}

variable "eb_environment_cname_prefix" {
  description = "Optional CNAME prefix for Elastic Beanstalk environment URL"
  type        = string
  default     = ""
}

variable "eb_environment_description" {
  description = "Optional description for Elastic Beanstalk environment"
  type        = string
  default     = ""
}

variable "alb_scheme" {
  description = "ALB scheme for Elastic Beanstalk (internal or internet-facing)"
  type        = string
  default     = "internet-facing"

  validation {
    condition     = contains(["internal", "internet-facing"], var.alb_scheme)
    error_message = "alb_scheme must be either 'internal' or 'internet-facing'."
  }
}

variable "eb_environment_variables" {
  description = "Map of environment variables to inject into Elastic Beanstalk application environment"
  type        = map(string)
  default     = {}
}

# =============================================================================
# Shared ALB
# =============================================================================
variable "enable_shared_alb" {
  description = "Create a shared ALB for multiple apps (true) or let EB manage its own ALB (false)"
  type        = bool
  default     = false
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN for HTTPS on shared ALB (leave empty for HTTP only)"
  type        = string
  default     = ""
}


