################################################################################
# CloudWatch Alarms Module
# Creates monitoring alarms for Elastic Beanstalk:
#   - CPU Utilization (ASG)
#   - ALB Unhealthy Host Count
#   - ALB Target Response Latency
#   - EB Environment Health
# All alarms publish to a configurable SNS topic.
################################################################################

# -----------------------------------------------------------------------------
# SNS Topic for alarm notifications (created if not provided externally)
# -----------------------------------------------------------------------------
resource "aws_sns_topic" "alarms" {
  count = var.create_sns_topic ? 1 : 0
  name  = "${var.environment}-eb-alarms"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "${var.environment}-eb-alarms"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

locals {
  sns_topic_arn = var.create_sns_topic ? aws_sns_topic.alarms[0].arn : var.sns_topic_arn
}

# Optional email subscription
resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = local.sns_topic_arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# -----------------------------------------------------------------------------
# Alarm 1: CPU Utilization (Auto Scaling Group)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.environment}-eb-cpu-utilization-high"
  alarm_description   = "CPU utilization exceeds ${var.cpu_threshold}% for ${var.environment} EB environment"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold
  treat_missing_data  = "breaching"

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  alarm_actions = [local.sns_topic_arn]
  ok_actions    = [local.sns_topic_arn]

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "${var.environment}-eb-cpu-high"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Alarm 2: ALB Unhealthy Host Count
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.environment}-eb-unhealthy-hosts"
  alarm_description   = "Unhealthy host count > 0 on ALB target group for ${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = var.target_group_arn_suffix
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [local.sns_topic_arn]
  ok_actions    = [local.sns_topic_arn]

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "${var.environment}-eb-unhealthy-hosts"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Alarm 3: ALB Target Response Latency (p99)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "latency_high" {
  alarm_name          = "${var.environment}-eb-latency-high"
  alarm_description   = "ALB target response time exceeds ${var.latency_threshold}s for ${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  extended_statistic  = "p99"
  threshold           = var.latency_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [local.sns_topic_arn]
  ok_actions    = [local.sns_topic_arn]

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "${var.environment}-eb-latency-high"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Alarm 4: EB Environment Health Status
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "env_health" {
  alarm_name          = "${var.environment}-eb-environment-health"
  alarm_description   = "EB environment health degraded for ${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "EnvironmentHealth"
  namespace           = "AWS/ElasticBeanstalk"
  period              = 300
  statistic           = "Average"
  threshold           = 15 # 0=Ok, 5=Info, 10=Unknown, 15=Warning, 20=Degraded, 25=Severe
  treat_missing_data  = "breaching"

  dimensions = {
    EnvironmentName = var.eb_environment_name
  }

  alarm_actions = [local.sns_topic_arn]
  ok_actions    = [local.sns_topic_arn]

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "${var.environment}-eb-env-health"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
