################################################################################
# VPC Module — Variables
################################################################################

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (must provide exactly 2)"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly 2 public subnet CIDRs are required for HA across 2 AZs."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (must provide exactly 2)"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Exactly 2 private subnet CIDRs are required for HA across 2 AZs."
  }
}
