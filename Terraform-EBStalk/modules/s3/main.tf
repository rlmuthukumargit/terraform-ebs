################################################################################
# S3 Module — Main
# Manages the artifact bucket for application JARs/WARs
################################################################################

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.resource_prefix}-artifacts-${data.aws_caller_identity.current.account_id}"

  # Prevent accidental deletion of the bucket
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "${var.resource_prefix}-artifacts-${data.aws_caller_identity.current.account_id}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Enable versioning so we can roll back or recover old versions of JARs
resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Ensure the bucket is private (Block all public access)
resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable default server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -----------------------------------------------------------------------------
# Upload Application Artifact
# -----------------------------------------------------------------------------
resource "aws_s3_object" "artifact" {
  count  = var.manage_artifact_object ? 1 : 0
  bucket = aws_s3_bucket.artifacts.id
  key    = var.app_s3_key
  source = var.app_source_file

  # Forces Terraform to re-upload if the local JAR file changes
  etag = filemd5(var.app_source_file)
}
