################################################################################
# Elastic Beanstalk Module
# Creates an EB Application, Application Version (from S3 JAR/WAR),
# and Environment with ALB, Auto Scaling, and HA configuration.
################################################################################

# -----------------------------------------------------------------------------
# IAM — Instance Profile for EC2 instances managed by EB
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "${var.app_name}-${var.environment}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-ec2-role"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_web_tier" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "ec2_worker_tier" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "ec2_multicontainer" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

# S3 read access so instances can fetch the app artifact
resource "aws_iam_role_policy_attachment" "ec2_s3_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.app_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# IAM — Service Role for Elastic Beanstalk
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "eb_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["elasticbeanstalk.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eb_service_role" {
  name               = "${var.app_name}-${var.environment}-eb-service-role"
  assume_role_policy = data.aws_iam_policy_document.eb_assume.json

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}-eb-service-role"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "eb_enhanced_health" {
  role       = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "eb_managed_updates" {
  role       = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
}

# -----------------------------------------------------------------------------
# Elastic Beanstalk Application
# -----------------------------------------------------------------------------
resource "aws_elastic_beanstalk_application" "this" {
  name        = "${var.app_name}-${var.environment}"
  description = "${var.app_name} application for ${var.environment} environment"

  appversion_lifecycle {
    service_role          = aws_iam_role.eb_service_role.arn
    max_count             = var.app_version_max_count
    delete_source_from_s3 = false
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "${var.app_name}-${var.environment}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Application Version — sourced from S3 bucket (JAR / WAR)
# -----------------------------------------------------------------------------
resource "aws_elastic_beanstalk_application_version" "this" {
  name        = "${var.app_name}-${var.environment}-${var.app_version_label}"
  application = aws_elastic_beanstalk_application.this.name
  description = "Version ${var.app_version_label} deployed from s3://${var.app_s3_bucket}/${var.app_s3_key}"
  bucket      = var.app_s3_bucket
  key         = var.app_s3_key

  tags = {
    Name        = "${var.app_name}-${var.environment}-${var.app_version_label}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Elastic Beanstalk Environment — LoadBalanced, ALB, Auto Scaling
# -----------------------------------------------------------------------------
locals {
  eb_environment_name        = trimspace(var.eb_environment_name) != "" ? trimspace(var.eb_environment_name) : "${var.app_name}-${var.environment}-env"
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
    prevent_destroy = true
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

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", var.public_subnet_ids)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = var.alb_scheme
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

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.eb_service_role.arn
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

  # Optional custom ALB security groups
  dynamic "setting" {
    for_each = length(var.alb_security_group_ids) > 0 ? [1] : []
    content {
      namespace = "aws:elbv2:loadbalancer"
      name      = "SecurityGroups"
      value     = join(",", var.alb_security_group_ids)
    }
  }

  # ALB listener on port 80
  setting {
    namespace = "aws:elbv2:listener:default"
    name      = "ListenerEnabled"
    value     = "true"
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
    value     = aws_iam_instance_profile.ec2_profile.name
  }

  dynamic "setting" {
    for_each = length(var.instance_security_group_ids) > 0 ? [1] : []
    content {
      namespace = "aws:autoscaling:launchconfiguration"
      name      = "SecurityGroups"
      value     = join(",", var.instance_security_group_ids)
    }
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
    Name        = "${var.app_name}-${var.environment}-env"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

