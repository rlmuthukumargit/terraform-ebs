################################################################################
# Security Groups Module - Variables
################################################################################

variable "resource_prefix" {
  description = "A naming prefix for all resources"
  type        = string
}

variable "app_name" {
  description = "Application name used for tagging/naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups are created"
  type        = string
}

variable "alb_ingress_cidrs" {
  description = "CIDRs allowed to access the ALB listener"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "alb_listener_port" {
  description = "ALB listener port"
  type        = number
  default     = 80
}

variable "app_port" {
  description = "Application port on Elastic Beanstalk EC2 instances"
  type        = number
  default     = 80
}
