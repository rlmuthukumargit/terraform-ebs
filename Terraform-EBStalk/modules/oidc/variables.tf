################################################################################
# OIDC Module — Variables
################################################################################

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL (e.g., https://token.actions.githubusercontent.com for GitHub Actions)"
  type        = string
  default     = "https://token.actions.githubusercontent.com"
}

variable "oidc_thumbprints" {
  description = "List of server certificate thumbprints for the OIDC provider"
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # GitHub Actions thumbprint
}

variable "oidc_client_ids" {
  description = "List of client IDs (audiences) for the OIDC provider"
  type        = list(string)
  default     = ["sts.amazonaws.com"]
}

variable "allowed_subjects" {
  description = "List of allowed OIDC subjects (e.g., repo:org/repo:ref:refs/heads/main)"
  type        = list(string)
}

variable "oidc_role_policy_arn" {
  description = "IAM policy ARN to attach to the OIDC deploy role"
  type        = string
  default     = "arn:aws:iam::aws:policy/AdministratorAccess"
}
