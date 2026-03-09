################################################################################
# Provider Configuration
#
# Authentication: OIDC via AssumeRoleWithWebIdentity
# - No static access keys or secret keys
# - CI/CD pipeline (Azure DevOps, GitHub Actions, GitLab CI) supplies a
#   web identity token
# - The provider assumes a role in the target account using that token
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
  # Remote Backend (Azure Blob Storage)
  #
  # Keep this block partial and pass backend settings during `terraform init`
  # from the pipeline (resource group, storage account, container, key).
  # ---------------------------------------------------------------------------
  backend "azurerm" {}
}

# -----------------------------------------------------------------------------
# AWS Provider - OIDC-based authentication (no access key / secret key)
#
# How it works:
#   1. Your CI/CD pipeline (e.g., GitHub Actions) generates a web identity token
#   2. The token is written to a file at $AWS_WEB_IDENTITY_TOKEN_FILE
#   3. Terraform reads the token and calls STS AssumeRoleWithWebIdentity
#   4. STS returns temporary credentials scoped to the target account
#
# Required environment variables (set by CI/CD):
#   AWS_WEB_IDENTITY_TOKEN_FILE  - path to the token file
#   AWS_ROLE_ARN                 - ARN of the role to assume (or set below)
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  assume_role_with_web_identity {
    role_arn                = "arn:aws:iam::${var.aws_account_id}:role/${var.environment}-${var.oidc_role_name}"
    session_name            = "terraform-${var.environment}"
    web_identity_token_file = var.web_identity_token_file
  }

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.app_name
    }
  }
}

# Additional variable for the token file path
variable "web_identity_token_file" {
  description = "Path to the OIDC web identity token file (set by CI/CD, e.g. GitHub Actions ACTIONS_ID_TOKEN_REQUEST_TOKEN)"
  type        = string
  default     = ""
}
