################################################################################
# CloudWatch Alarms Module — Outputs
################################################################################

output "sns_topic_arn" {
  description = "ARN of the SNS topic used for alarm notifications"
  value       = local.sns_topic_arn
}

output "alarm_arns" {
  description = "Map of all CloudWatch alarm ARNs"
  value = {
    cpu_high        = aws_cloudwatch_metric_alarm.cpu_high.arn
    unhealthy_hosts = aws_cloudwatch_metric_alarm.unhealthy_hosts.arn
    latency_high    = aws_cloudwatch_metric_alarm.latency_high.arn
    env_health      = aws_cloudwatch_metric_alarm.env_health.arn
  }
}
