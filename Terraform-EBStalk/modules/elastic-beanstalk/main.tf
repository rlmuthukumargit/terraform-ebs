################################################################################
# Elastic Beanstalk Module
# Creates an EB Application, Application Version (from S3 JAR/WAR),
# and Environment with ALB, Auto Scaling, and HA configuration.
################################################################################

# -----------------------------------------------------------------------------
# Elastic Beanstalk Application
# -----------------------------------------------------------------------------
resource "aws_elastic_beanstalk_application" "this" {
  name        = var.resource_prefix
  description = "${var.app_name} application for ${var.environment} environment"

  appversion_lifecycle {
    service_role          = var.eb_service_role_arn
    max_count             = var.app_version_max_count
    delete_source_from_s3 = false
  }

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name        = var.resource_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Application Version — sourced from S3 bucket (JAR / WAR)
# -----------------------------------------------------------------------------
resource "aws_elastic_beanstalk_application_version" "this" {
  name        = "${var.resource_prefix}-${var.app_version_label}"
  application = aws_elastic_beanstalk_application.this.name
  description = "Version ${var.app_version_label} deployed from s3://${var.app_s3_bucket}/${var.app_s3_key}"
  bucket      = var.app_s3_bucket
  key         = var.app_s3_key

  # IMPORTANT: Elastic Beanstalk needs the physical object to exist in S3 before this resource is created
  # We use the key to imply a dependency, but an explicit depends_on is safer here if passed through root
  # However, Terraform requires depends_on to be based on module outputs or directly passed resources.
  # Since app_s3_key and app_s3_bucket are now output from the S3 module, passing them creates an implicit dependency.

  tags = {
    Name        = "${var.resource_prefix}-${var.app_version_label}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  lifecycle {
    ignore_changes = [
      tags,
      tags_all
    ]
  }
}

# -----------------------------------------------------------------------------
# Elastic Beanstalk Environment — LoadBalanced, ALB, Auto Scaling
# -----------------------------------------------------------------------------
locals {
  eb_environment_name        = trimspace(var.eb_environment_name) != "" ? trimspace(var.eb_environment_name) : "${var.resource_prefix}-env"
  eb_environment_description = trimspace(var.eb_environment_description) != "" ? trimspace(var.eb_environment_description) : "${var.app_name} environment for ${var.environment}"
  eb_cname_prefix            = trimspace(var.eb_environment_cname_prefix)
}
resource "aws_elastic_beanstalk_environment" "this" {
  name                = local.eb_environment_name
  application         = aws_elastic_beanstalk_application.this.name
  solution_stack_name = var.solution_stack_name
  version_label       = aws_elastic_beanstalk_application_version.this.name
  tier                = "WebServer"
  description         = local.eb_environment_description
  cname_prefix        = local.eb_cname_prefix != "" ? local.eb_cname_prefix : null

  lifecycle {
    ignore_changes = [
      tags,
      tags_all
    ]
  }

  # ---------------------------------------------------------------------------
  # VPC Configuration
  # ---------------------------------------------------------------------------
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", var.private_subnet_ids)
  }

  # ELBSubnets — only needed when EB manages its own ALB
  dynamic "setting" {
    for_each = var.shared_alb_arn == "" ? [1] : []
    content {
      namespace = "aws:ec2:vpc"
      name      = "ELBSubnets"
      value     = join(",", var.public_subnet_ids)
    }
  }

  # ELBScheme — only needed when EB manages its own ALB
  dynamic "setting" {
    for_each = var.shared_alb_arn == "" ? [1] : []
    content {
      namespace = "aws:ec2:vpc"
      name      = "ELBScheme"
      value     = var.alb_scheme
    }
  }

  # ---------------------------------------------------------------------------
  # Load Balancer — Application Load Balancer (ALB)
  # ---------------------------------------------------------------------------
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  # Shared ALB — attach to an existing ALB instead of creating a new one
  dynamic "setting" {
    for_each = var.shared_alb_arn != "" ? [1] : []
    content {
      namespace = "aws:elbv2:loadbalancer"
      name      = "SharedLoadBalancer"
      value     = var.shared_alb_arn
    }
  }

  dynamic "setting" {
    for_each = var.shared_alb_arn != "" ? [1] : []
    content {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "LoadBalancerIsShared"
      value     = "true"
    }
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = var.eb_service_role_arn
  }
  # Optional application environment variables
  dynamic "setting" {
    for_each = var.eb_environment_variables
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.key
      value     = setting.value
    }
  }

  # Optional custom ALB security groups (only when EB manages its own ALB)
  dynamic "setting" {
    for_each = var.shared_alb_arn == "" && length(var.alb_security_group_ids) > 0 ? [1] : []
    content {
      namespace = "aws:elbv2:loadbalancer"
      name      = "SecurityGroups"
      value     = join(",", var.alb_security_group_ids)
    }
  }

  # ALB listener on port 80 (only when EB manages its own ALB)
  dynamic "setting" {
    for_each = var.shared_alb_arn == "" ? [1] : []
    content {
      namespace = "aws:elbv2:listener:default"
      name      = "ListenerEnabled"
      value     = "true"
    }
  }

  # ---------------------------------------------------------------------------
  # Auto Scaling Group
  # ---------------------------------------------------------------------------
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = tostring(var.min_instances)
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = tostring(var.max_instances)
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "Availability Zones"
    value     = "Any 2"
  }

  # ---------------------------------------------------------------------------
  # Launch Configuration — Instance type + profile
  # ---------------------------------------------------------------------------
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = var.ec2_instance_profile_name
  }

  dynamic "setting" {
    for_each = length(var.instance_security_group_ids) > 0 ? [1] : []
    content {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "SecurityGroups"
      value     = join(",", var.instance_security_group_ids)
    }
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "RootVolumeSize"
    value     = var.root_volume_size
  }

  # ---------------------------------------------------------------------------
  # Auto Scaling Trigger (CPU based)
  # ---------------------------------------------------------------------------
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MeasureName"
    value     = "CPUUtilization"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Statistic"
    value     = "Average"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Unit"
    value     = "Percent"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = "70"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = "30"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Period"
    value     = "5"
  }

  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "BreachDuration"
    value     = "5"
  }

  # ---------------------------------------------------------------------------
  # Rolling Updates — zero-downtime deploys
  # ---------------------------------------------------------------------------
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateType"
    value     = "Health"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "MaxBatchSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "MinInstancesInService"
    value     = tostring(var.min_instances)
  }

  # ---------------------------------------------------------------------------
  # Health Reporting — enhanced
  # ---------------------------------------------------------------------------
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "HealthCheckSuccessThreshold"
    value     = "Ok"
  }

  # ---------------------------------------------------------------------------
  # Deployment Policy
  # ---------------------------------------------------------------------------
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "Rolling"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSizeType"
    value     = "Percentage"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSize"
    value     = "50"
  }

  # ---------------------------------------------------------------------------
  # CloudWatch Logs streaming
  # ---------------------------------------------------------------------------
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "DeleteOnTerminate"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = tostring(var.log_retention_days)
  }

  tags = {
    Name        = "${var.resource_prefix}-env"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

