################################################################################
# CloudWatch Alarms Module — Variables
################################################################################

variable "resource_prefix" {
  description = "A naming prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

# ------- Resource References -------
variable "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group to monitor"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer (e.g., app/my-alb/50dc6c495c0c9188)"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the ALB target group (e.g., targetgroup/my-tg/73e2d6bc24d8a067)"
  type        = string
}

variable "eb_environment_name" {
  description = "Name of the Elastic Beanstalk environment to monitor"
  type        = string
}

# ------- Thresholds -------
variable "cpu_threshold" {
  description = "CPU utilization threshold (%) to trigger alarm"
  type        = number
  default     = 80
}

variable "latency_threshold" {
  description = "ALB target response time threshold (seconds) to trigger alarm"
  type        = number
  default     = 1.5
}

# ------- SNS -------
variable "create_sns_topic" {
  description = "Whether to create a new SNS topic (true) or use an existing one (false)"
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "ARN of an existing SNS topic (required if create_sns_topic = false)"
  type        = string
  default     = ""
}

variable "alarm_email" {
  description = "Email address for alarm notifications (leave empty to skip email subscription)"
  type        = string
  default     = ""
}
