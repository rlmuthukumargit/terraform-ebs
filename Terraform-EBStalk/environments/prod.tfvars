################################################################################
# PROD Environment Configuration
################################################################################

# --- General ---
aws_region     = "us-east-1"
aws_account_id = "333333333333" # <-- Replace with your PROD AWS account ID
environment    = "prod"



# --- VPC ---
vpc_cidr             = "10.2.0.0/16"
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
private_subnet_cidrs = ["10.2.10.0/24", "10.2.20.0/24"]

# --- Elastic Beanstalk ---
app_name            = "my-app"
solution_stack_name = "64bit Amazon Linux 2023 v4.10.0 running Corretto 21"
instance_type       = "t3.medium"
min_instances       = 2
max_instances       = 6

# --- S3 Application Source ---
app_s3_bucket     = "my-app-artifacts-prod"  # <-- Replace with your S3 bucket
app_s3_key        = "releases/my-app-v1.jar" # <-- Replace with your JAR/WAR path
app_version_label = "v1"

# --- Logging ---
log_retention_days = 90

# --- CloudWatch Alarms (tight for production) ---
cpu_threshold     = 70
latency_threshold = 1.0
create_sns_topic  = true
alarm_email       = "" # <-- Add email for notifications

# --- Custom Security Groups ---
# Restrict this CIDR in production as needed.
alb_ingress_cidrs = ["0.0.0.0/0"]
alb_listener_port = 80
app_port          = 80

# --- Elastic Beanstalk Environment Info ---
eb_environment_name         = "my-app-prod-env"
eb_environment_cname_prefix = "myapp-prod-333333333333" # Domain: myapp-prod-333333333333.<region>.elasticbeanstalk.com
eb_environment_description  = "Production Elastic Beanstalk environment"

# --- ALB + EB App Environment Variables ---
alb_scheme = "internet-facing"
eb_environment_variables = {
  APP_ENV     = "prod"
  SERVER_PORT = "5000"
}

# --- Shared ALB (set to true to share one ALB across multiple apps) ---
enable_shared_alb = true
# alb_certificate_arn = ""  # Optional: ACM cert ARN for HTTPS
