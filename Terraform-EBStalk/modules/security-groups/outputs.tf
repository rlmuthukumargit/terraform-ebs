################################################################################
# Security Groups Module - Outputs
################################################################################

output "alb_security_group_id" {
  description = "Security group ID for the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "Security group ID for Elastic Beanstalk EC2 instances"
  value       = aws_security_group.ec2.id
}
