################################################################################
# Root Module — Orchestrates all sub-modules
# Usage: terraform plan -var-file="environments/dev.tfvars"
################################################################################

# -----------------------------------------------------------------------------
# 1. OIDC Provider (creates IAM OIDC IdP + deploy role in target account)
# -----------------------------------------------------------------------------
module "oidc" {
  source = "./modules/oidc"

  environment       = var.environment
  oidc_provider_url = var.oidc_provider_url
  oidc_thumbprints  = var.oidc_thumbprints
  oidc_client_ids   = var.oidc_client_ids
  allowed_subjects  = var.oidc_allowed_subjects
}

# -----------------------------------------------------------------------------
# 2. VPC (2-AZ, public + private subnets)
# -----------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# -----------------------------------------------------------------------------
# 3. Elastic Beanstalk (App + Version from S3 + Environment with ALB & ASG)
# -----------------------------------------------------------------------------
module "elastic_beanstalk" {
  source = "./modules/elastic-beanstalk"

  app_name            = var.app_name
  environment         = var.environment
  solution_stack_name = var.solution_stack_name
  instance_type       = var.instance_type
  min_instances       = var.min_instances
  max_instances       = var.max_instances

  # VPC wiring
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  # S3 app source
  app_s3_bucket     = var.app_s3_bucket
  app_s3_key        = var.app_s3_key
  app_version_label = var.app_version_label

  # Logging
  log_retention_days = var.log_retention_days
}

# -----------------------------------------------------------------------------
# 4. CloudWatch Alarms (CPU, Unhealthy Hosts, Latency, EB Health)
# -----------------------------------------------------------------------------
module "cloudwatch" {
  source = "./modules/cloudwatch"

  environment            = var.environment
  autoscaling_group_name = module.elastic_beanstalk.autoscaling_groups[0]
  alb_arn_suffix         = module.elastic_beanstalk.load_balancers[0]
  target_group_arn_suffix = var.target_group_arn_suffix
  eb_environment_name    = module.elastic_beanstalk.environment_name

  # Thresholds
  cpu_threshold     = var.cpu_threshold
  latency_threshold = var.latency_threshold

  # SNS
  create_sns_topic = var.create_sns_topic
  sns_topic_arn    = var.sns_topic_arn
  alarm_email      = var.alarm_email
}
