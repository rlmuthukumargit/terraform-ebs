################################################################################
# Provider Configuration
#
# Authentication modes:
#   1. Manual CLI   → run `aws configure` first, no extra env vars needed
#   2. OIDC (CI/CD) → uncomment the assume_role_with_web_identity block below
#                      and set AWS_WEB_IDENTITY_TOKEN_FILE + AWS_ROLE_ARN
################################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ---------------------------------------------------------------------------
  # Local backend for manual CLI runs.
  # backend "s3" {}
}

# -----------------------------------------------------------------------------
# AWS Provider
# For manual runs: uses credentials from `aws configure`
# For CI/CD:       uncomment the assume_role_with_web_identity block
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.app_name
    }
  }
}


