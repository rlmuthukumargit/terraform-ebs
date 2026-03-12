################################################################################
# ALB Module — Shared Application Load Balancer
#
# Creates a standalone ALB that can be shared across multiple Elastic Beanstalk
# environments or other services. Each app registers via listener rules.
################################################################################

resource "aws_lb" "this" {
  name               = "${var.resource_prefix}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  # Temporarily disabled so Terraform can update the scheme
  lifecycle {
    ignore_changes = [
      tags,
      tags_all,
      security_groups
    ]
  }

  tags = {
    Name        = "${var.resource_prefix}-alb"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# HTTP Listener (port 80)
# Default action returns 404 — each app adds its own listener rule
# -----------------------------------------------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No matching route"
      status_code  = "404"
    }
  }

  tags = {
    Name        = "${var.resource_prefix}-http"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# HTTPS Listener (port 443) — optional, created only if certificate ARN given
# -----------------------------------------------------------------------------
resource "aws_lb_listener" "https" {
  count = var.certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No matching route"
      status_code  = "404"
    }
  }

  tags = {
    Name        = "${var.resource_prefix}-https"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
