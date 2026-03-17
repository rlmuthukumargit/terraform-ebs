################################################################################
# Elastic Beanstalk Module — Outputs
################################################################################

output "app_name" {
  description = "Name of the Elastic Beanstalk application"
  value       = aws_elastic_beanstalk_application.this.name
}

output "environment_name" {
  description = "Name of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.this.name
}

output "environment_id" {
  description = "ID of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.this.id
}

output "endpoint_url" {
  description = "URL endpoint of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.this.endpoint_url
}

output "cname" {
  description = "CNAME of the Elastic Beanstalk environment"
  value       = aws_elastic_beanstalk_environment.this.cname
}

output "domain_name" {
  description = "Full Elastic Beanstalk domain name (<cname_prefix>.<region>.elasticbeanstalk.com)"
  value       = aws_elastic_beanstalk_environment.this.cname
}

output "autoscaling_groups" {
  description = "Auto Scaling Groups associated with the EB environment"
  value       = aws_elastic_beanstalk_environment.this.autoscaling_groups
}

output "load_balancers" {
  description = "Load Balancers associated with the EB environment"
  value       = aws_elastic_beanstalk_environment.this.load_balancers
}

output "app_version" {
  description = "Currently deployed application version label"
  value       = var.create_app_version ? aws_elastic_beanstalk_application_version.this[0].name : "sample-app"
}
