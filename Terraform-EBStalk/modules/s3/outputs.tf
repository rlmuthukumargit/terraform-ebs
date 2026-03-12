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
  description = "The S3 object key of the uploaded application artifact"
  value       = aws_s3_object.artifact.key
}

output "object_version_id" {
  description = "The S3 version ID of the uploaded artifact (used for Elastic Beanstalk versioning)"
  value       = aws_s3_object.artifact.version_id
}
