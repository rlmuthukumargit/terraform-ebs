################################################################################
# OIDC Module — Outputs
################################################################################

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC identity provider"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_role_arn" {
  description = "ARN of the IAM role that can be assumed via OIDC"
  value       = aws_iam_role.oidc_role.arn
}

output "oidc_role_name" {
  description = "Name of the IAM role that can be assumed via OIDC"
  value       = aws_iam_role.oidc_role.name
}
