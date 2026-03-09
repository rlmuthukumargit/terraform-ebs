################################################################################
# ALB Module — Outputs
################################################################################

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route53 zone ID of the ALB (for alias records)"
  value       = aws_lb.this.zone_id
}

output "alb_arn_suffix" {
  description = "ARN suffix for CloudWatch metrics"
  value       = aws_lb.this.arn_suffix
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener (empty if HTTPS not enabled)"
  value       = length(aws_lb_listener.https) > 0 ? aws_lb_listener.https[0].arn : ""
}
