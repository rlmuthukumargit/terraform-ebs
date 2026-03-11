################################################################################
# IAM Roles Module - Outputs
################################################################################

output "ec2_instance_profile_name" {
  description = "The name of the IAM instance profile for EC2 instances"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "eb_service_role_arn" {
  description = "The ARN of the IAM service role for Elastic Beanstalk"
  value       = aws_iam_role.eb_service_role.arn
}
