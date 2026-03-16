################################################################################
# S3 Module — Outputs
################################################################################

output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.artifacts.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.artifacts.arn
}

output "object_key" {
  description = "The S3 object key of the application artifact"
  value       = var.manage_artifact_object ? aws_s3_object.artifact[0].key : var.app_s3_key
}

output "object_version_id" {
  description = "The S3 version ID of the application artifact (if managed)"
  value       = var.manage_artifact_object ? aws_s3_object.artifact[0].version_id : null
}
