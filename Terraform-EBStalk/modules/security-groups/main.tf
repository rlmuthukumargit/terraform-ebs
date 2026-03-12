################################################################################
# Security Groups Module
# - ALB SG: internet ingress on listener port
# - EC2 SG: ingress from ALB SG on app port
################################################################################

resource "aws_security_group" "alb" {
  name        = "${var.app_name}-${var.environment}-alb-sg"
  description = "ALB security group for ${var.app_name} ${var.environment}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.alb_listener_port
    to_port     = var.alb_listener_port
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name        = "${var.resource_prefix}-alb-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "ec2" {
  name        = "${var.app_name}-${var.environment}-ec2-sg"
  description = "EB EC2 security group for ${var.app_name} ${var.environment}"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name        = "${var.resource_prefix}-ec2-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
