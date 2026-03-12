################################################################################
# DEV Environment Configuration
################################################################################

# --- General ---
aws_region     = "us-east-1"
aws_account_id = "911287867452" # <-- Replace with your dev AWS account ID
environment    = "dev"
resource_prefix = "my-app-dev"

# --- VPC ---
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# --- Elastic Beanstalk ---
app_name            = "my-app"
solution_stack_name = "64bit Amazon Linux 2023 v4.10.0 running Corretto 21"
instance_type       = "t3.micro"
min_instances       = 1
max_instances       = 2

# --- S3 Application Source ---
# app_s3_bucket     = "my-app-artifacts-dev-911287867452"   # <-- Managed by Terraform module now
app_source_file   = "./sample-app/my-app-v1.jar" # <-- Update path if JAR is somewhere else
app_s3_key        = "releases/my-app-v1.jar" # <-- Replace with your JAR/WAR target pattern
app_version_label = "v1"

# --- Logging ---
log_retention_days = 14

# --- CloudWatch Alarms (relaxed for dev) ---
cpu_threshold     = 85
latency_threshold = 2.0
create_sns_topic  = true
alarm_email       = "" # <-- Add email for notifications

# --- Custom Security Groups ---
alb_ingress_cidrs = ["0.0.0.0/0"]
alb_listener_port = 80
app_port          = 80

# --- Elastic Beanstalk Environment Info ---
eb_environment_name         = "my-app-dev-env"
eb_environment_cname_prefix = "myapp-dev-911287867452" # Domain: myapp-dev-911287867452.<region>.elasticbeanstalk.com
eb_environment_description  = "Development Elastic Beanstalk environment"

# --- ALB + EB App Environment Variables ---
alb_scheme = "internet-facing"
eb_environment_variables = {
  APP_ENV     = "dev"
  SERVER_PORT = "5000"
}

# --- Shared ALB (set to true to share one ALB across multiple apps) ---
enable_shared_alb = true
# alb_certificate_arn = ""  # Optional: ACM cert ARN for HTTPS
