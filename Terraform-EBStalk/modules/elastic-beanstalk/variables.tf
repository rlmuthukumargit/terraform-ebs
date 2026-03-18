################################################################################
# Elastic Beanstalk Module - Variables
################################################################################

variable "resource_prefix" {
  description = "A naming prefix for all resources"
  type        = string
}

variable "app_name" {
  description = "Name of the Elastic Beanstalk application"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "solution_stack_name" {
  description = "Elastic Beanstalk solution stack (platform). Example: '64bit Amazon Linux 2023 v4.0.3 running Corretto 17'"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for EB environment"
  type        = string
  default     = "t3.micro"
}

variable "min_instances" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 4
}

variable "root_volume_size" {
  description = "The size of the EBS root volume (in GB)"
  type        = number
  default     = 20
}

# ------- VPC -------
variable "vpc_id" {
  description = "VPC ID to deploy the EB environment into"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EC2 instances"
  type        = list(string)
}

variable "alb_security_group_ids" {
  description = "Optional ALB security group IDs for Elastic Beanstalk load balancer"
  type        = list(string)
  default     = []
}

variable "instance_security_group_ids" {
  description = "Optional EC2 instance security group IDs for Elastic Beanstalk instances"
  type        = list(string)
  default     = []
}

# ------- S3 App Source -------

variable "app_version_label" {
  description = "Version label for the application version"
  type        = string
  default     = "v1"
}

variable "app_s3_bucket" {
  description = "S3 bucket containing the application ZIP bundle"
  type        = string
  default     = ""
}

variable "app_s3_key" {
  description = "S3 key for the application ZIP bundle"
  type        = string
  default     = ""
}

variable "app_version_max_count" {
  description = "Maximum number of application versions to retain"
  type        = number
  default     = 10
}

# ------- Logging -------
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
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

# ------- Shared ALB -------
variable "shared_alb_arn" {
  description = "ARN of a shared ALB. If set, EB uses this ALB instead of creating its own."
  type        = string
  default     = ""
}

# ------- IAM Roles -------
variable "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile for Elastic Beanstalk instances"
  type        = string
}

variable "eb_service_role_arn" {
  description = "ARN of the Elastic Beanstalk service role"
  type        = string
}

