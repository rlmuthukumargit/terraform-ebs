################################################################################
# DEV Environment Configuration
################################################################################

# --- General ---
aws_region      = "us-east-1"
aws_account_id  = "911287867452" # <-- Replace with your dev AWS account ID
environment     = "dev"
resource_prefix = "tss-ebs-dev-new"

# --- VPC ---
vpc_id = "vpc-0975e41529fdd220e" # <-- Replace with your existing VPC ID
subnet_ids = [
  "subnet-0db123d54c271e391", # <-- Replace with your existing Subnet IDs (3 required)
  "subnet-07f28a28b8830044b",
  "subnet-0b17ab8abf3a8b378"
]

# --- Elastic Beanstalk ---
app_name            = "tss-app"
solution_stack_name = "64bit Amazon Linux 2023 v4.10.0 running Corretto 21"
instance_type       = "t3.medium"
min_instances       = 1
max_instances       = 2
root_volume_size    = 20

# --- S3 Application Source ---
app_version_label = "v9"
app_s3_bucket     = "tss-ebs-dev-artifacts-911287867452"
app_s3_key        = "releases/snapshot.jar" # Path to your ZIP file in S3
app_local_path    = "snapshot-v9.jar"          # Local file to upload

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
# eb_environment_name         = "my-app-dev-env"
eb_environment_cname_prefix = "tss-app-dev" # Domain: myapp-dev-911287867452.<region>.elasticbeanstalk.com
# eb_environment_description  = "Development Elastic Beanstalk environment"

# --- ALB + EB App Environment Variables ---
alb_scheme = "internal"
eb_environment_variables = {
  APP_ENV     = "dev"
  SERVER_PORT = "8080"
  PORT        = "8080"
}

# --- Shared ALB (set to true to share one ALB across multiple apps) ---
enable_shared_alb = true
# alb_certificate_arn = ""  # Optional: ACM cert ARN for HTTPS

# --- CI/CD Readiness ---
