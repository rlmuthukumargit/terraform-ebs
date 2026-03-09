################################################################################
# OIDC Identity Provider Module
# Creates an IAM OIDC provider and a role that can be assumed via
# AssumeRoleWithWebIdentity (e.g., from GitHub Actions, GitLab CI, etc.)
################################################################################

# -----------------------------------------------------------------------------
# OIDC Identity Provider
# -----------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "this" {
  url             = var.oidc_provider_url
  client_id_list  = var.oidc_client_ids
  thumbprint_list = var.oidc_thumbprints

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "${var.environment}-oidc-provider"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# IAM Role — trusted by the OIDC provider
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "oidc_trust" {
  statement {
    sid     = "AllowOIDCAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    # Scope to specific subjects (e.g., repo:org/repo:ref:refs/heads/main)
    condition {
      test     = "StringLike"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = var.allowed_subjects
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = var.oidc_client_ids
    }
  }
}

resource "aws_iam_role" "oidc_role" {
  name               = "${var.environment}-oidc-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.oidc_trust.json
  max_session_duration = 3600

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "${var.environment}-oidc-deploy-role"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Policy attachment — configurable policy ARN (defaults to AdministratorAccess)
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "oidc_policy" {
  role       = aws_iam_role.oidc_role.name
  policy_arn = var.oidc_role_policy_arn
}
