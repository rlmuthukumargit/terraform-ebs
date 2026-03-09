################################################################################
# Root Module - Outputs
################################################################################

# ------- OIDC -------
output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC identity provider"
  value       = module.oidc.oidc_provider_arn
}

output "oidc_role_arn" {
  description = "ARN of the OIDC deploy role"
  value       = module.oidc.oidc_role_arn
}

# ------- VPC -------
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# ------- Security Groups -------
output "alb_security_group_id" {
  description = "Custom ALB security group ID"
  value       = module.security_groups.alb_security_group_id
}

output "ec2_security_group_id" {
  description = "Custom EB EC2 security group ID"
  value       = module.security_groups.ec2_security_group_id
}

# ------- Elastic Beanstalk -------
output "eb_app_name" {
  description = "Elastic Beanstalk application name"
  value       = module.elastic_beanstalk.app_name
}

output "eb_environment_name" {
  description = "Elastic Beanstalk environment name"
  value       = module.elastic_beanstalk.environment_name
}

output "eb_endpoint_url" {
  description = "Elastic Beanstalk environment endpoint URL"
  value       = module.elastic_beanstalk.endpoint_url
}

output "eb_cname" {
  description = "Elastic Beanstalk environment CNAME"
  value       = module.elastic_beanstalk.cname
}

output "eb_app_version" {
  description = "Currently deployed application version"
  value       = module.elastic_beanstalk.app_version
}

output "autoscaling_groups" {
  description = "Auto Scaling Groups created by EB"
  value       = module.elastic_beanstalk.autoscaling_groups
}

output "load_balancers" {
  description = "Load Balancers created by EB"
  value       = module.elastic_beanstalk.load_balancers
}

# ------- CloudWatch -------
output "cloudwatch_alarm_arns" {
  description = "Map of CloudWatch alarm ARNs"
  value       = module.cloudwatch.alarm_arns
}

output "sns_topic_arn" {
  description = "SNS topic ARN used for alarm notifications"
  value       = module.cloudwatch.sns_topic_arn
}
