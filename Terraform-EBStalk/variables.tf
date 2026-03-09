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

# =============================================================================
# OIDC Authentication
# =============================================================================
variable "oidc_provider_url" {
  description = "OIDC provider URL (default: GitHub Actions)"
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "oidc_thumbprints" {
  description = "List of OIDC provider certificate thumbprints"
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

variable "oidc_client_ids" {
  description = "OIDC audience / client IDs"
  type        = list(string)
  default     = ["sts.amazonaws.com"]
}

variable "oidc_allowed_subjects" {
  description = "OIDC subject claims allowed to assume the deploy role (e.g., repo:org/repo:ref:refs/heads/main)"
  type        = list(string)
}

variable "oidc_role_name" {
  description = "Name of the IAM role used for OIDC web identity assume"
  type        = string
  default     = "oidc-deploy-role"
}

# =============================================================================
# VPC / Networking
# =============================================================================
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (exactly 2)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (exactly 2)"
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
  default     = "64bit Amazon Linux 2023 v4.0.3 running Corretto 17"
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

# =============================================================================
# S3 Application Source
# =============================================================================
variable "app_s3_bucket" {
  description = "S3 bucket containing the application JAR/WAR"
  type        = string
}

variable "app_s3_key" {
  description = "S3 object key for the application JAR/WAR"
  type        = string
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
