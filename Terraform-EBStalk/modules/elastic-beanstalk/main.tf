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
  tier                = "WebServer"
  version_label       = var.app_version_label
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
  # Isolated VPC Bootstrap Bypass
  # Allows the environment to finalize creation even if the default sample app
  # deployment fails (which happens due to lack of internet for Maven).
  # ---------------------------------------------------------------------------
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "IgnoreCondition"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "Timeout"
    value     = "600"
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

  # Ensure instances can communicate with EB service immediately on launch
  depends_on = [
    aws_vpc_endpoint.eb,
    aws_vpc_endpoint.eb_health,
    aws_vpc_endpoint.sqs,
    aws_vpc_endpoint.sts,
    aws_vpc_endpoint.ec2,
    aws_vpc_endpoint.logs,
    aws_vpc_endpoint.ssm,
    aws_vpc_endpoint.ssmmessages,
    aws_vpc_endpoint.ec2messages,
    aws_vpc_endpoint.autoscaling,
    aws_vpc_endpoint.monitoring,
    aws_vpc_endpoint.cloudformation,
    aws_vpc_endpoint.s3
  ]
}

# -----------------------------------------------------------------------------
# VPC Endpoints for Internal Connectivity
# Required for instances in private subnets to reach EB service without NAT/Public IP
# -----------------------------------------------------------------------------

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.resource_prefix}-vpce-sg"
  description = "Security group for VPC Endpoints"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  tags = {
    Name        = "${var.resource_prefix}-vpce-sg"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "eb" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.elasticbeanstalk"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.resource_prefix}-eb-vpce"
  }
}

resource "aws_vpc_endpoint" "eb_health" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.elasticbeanstalk-health"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.resource_prefix}-eb-health-vpce"
  }
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sqs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.resource_prefix}-sqs-vpce"
  }
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.resource_prefix}-sts-vpce"
  }
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.resource_prefix}-ec2-vpce"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.resource_prefix}-logs-vpce"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.resource_prefix}-ssm-vpce"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.resource_prefix}-ssm-msg-vpce"
  }
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.resource_prefix}-ec2-msg-vpce"
  }
}

resource "aws_vpc_endpoint" "autoscaling" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.autoscaling"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.resource_prefix}-asg-vpce"
  }
}

resource "aws_vpc_endpoint" "monitoring" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.resource_prefix}-monitoring-vpce"
  }
}

resource "aws_vpc_endpoint" "cloudformation" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.cloudformation"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.resource_prefix}-cfn-vpce"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.aws_route_tables.all.ids

  tags = {
    Name = "${var.resource_prefix}-s3-vpce"
  }
}

data "aws_region" "current" {}

data "aws_route_tables" "all" {
  vpc_id = var.vpc_id
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

