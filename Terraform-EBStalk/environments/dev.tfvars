################################################################################
# DEV Environment Configuration
################################################################################

# --- General ---
aws_region     = "us-east-1"
aws_account_id = "111111111111" # <-- Replace with your dev AWS account ID
environment    = "dev"

# --- OIDC ---
# For Azure DevOps: Use format "sc://<org>/<project>/<service-connection-name>"
oidc_provider_url     = "https://vstoken.dev.azure.com/<your-azure-devops-org-id>"  # <-- Replace with your Azure DevOps org
oidc_allowed_subjects = ["sc://<org>/<project>/aws-dev-oidc"]                        # <-- Update with your service connection

# --- VPC ---
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# --- Elastic Beanstalk ---
app_name            = "my-app"
solution_stack_name = "64bit Amazon Linux 2023 v4.0.3 running Corretto 17"
instance_type       = "t3.micro"
min_instances       = 1
max_instances       = 2

# --- S3 Application Source ---
app_s3_bucket     = "my-app-artifacts-dev"    # <-- Replace with your S3 bucket
app_s3_key        = "releases/my-app-v1.jar"  # <-- Replace with your JAR/WAR path
app_version_label = "v1"

# --- Logging ---
log_retention_days = 14

# --- CloudWatch Alarms (relaxed for dev) ---
cpu_threshold     = 85
latency_threshold = 2.0
create_sns_topic  = true
alarm_email       = ""  # <-- Add email for notifications
