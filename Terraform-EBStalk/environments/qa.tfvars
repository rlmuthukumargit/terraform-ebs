################################################################################
# QA Environment Configuration
################################################################################

# --- General ---
aws_region     = "us-east-1"
aws_account_id = "222222222222" # <-- Replace with your QA AWS account ID
environment    = "qa"

# --- OIDC ---
oidc_provider_url     = "https://token.actions.githubusercontent.com"
oidc_allowed_subjects = ["repo:your-org/your-repo:ref:refs/heads/release/*"] # <-- Update

# --- VPC ---
vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.20.0/24"]

# --- Elastic Beanstalk ---
app_name            = "my-app"
solution_stack_name = "64bit Amazon Linux 2023 v4.0.3 running Corretto 17"
instance_type       = "t3.small"
min_instances       = 2
max_instances       = 4

# --- S3 Application Source ---
app_s3_bucket     = "my-app-artifacts-qa"     # <-- Replace with your S3 bucket
app_s3_key        = "releases/my-app-v1.jar"  # <-- Replace with your JAR/WAR path
app_version_label = "v1"

# --- Logging ---
log_retention_days = 30

# --- CloudWatch Alarms (moderate for QA) ---
cpu_threshold     = 80
latency_threshold = 1.5
create_sns_topic  = true
alarm_email       = ""  # <-- Add email for notifications
