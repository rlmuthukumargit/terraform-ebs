# -----------------------------------------------------------------------------
# 1. Managed S3 Artifact Bucket
# -----------------------------------------------------------------------------
module "s3" {
  source = "./modules/s3"

  resource_prefix        = var.resource_prefix
  environment            = var.environment
  app_source_file        = var.app_source_file
  app_s3_key             = var.app_s3_key
  manage_artifact_object = var.manage_artifact_object
}

locals {
  vpc_id             = var.vpc_id
  public_subnet_ids  = var.subnet_ids
  private_subnet_ids = var.subnet_ids
}

# -----------------------------------------------------------------------------
# 3. Security Groups (custom ALB + EC2 SGs for Elastic Beanstalk)
# -----------------------------------------------------------------------------
module "security_groups" {
  source = "./modules/security-groups"

  resource_prefix   = var.resource_prefix
  app_name          = var.app_name
  environment       = var.environment
  vpc_id            = local.vpc_id
  alb_ingress_cidrs = var.alb_ingress_cidrs
  alb_listener_port = var.alb_listener_port
  app_port          = var.app_port
}

# -----------------------------------------------------------------------------
# 4. Shared ALB (optional — for running multiple apps behind one ALB)
# -----------------------------------------------------------------------------
module "alb" {
  count  = var.enable_shared_alb ? 1 : 0
  source = "./modules/alb"

  resource_prefix    = var.resource_prefix
  app_name           = var.app_name
  environment        = var.environment
  vpc_id             = local.vpc_id
  subnet_ids         = local.public_subnet_ids
  security_group_ids = [module.security_groups.alb_security_group_id]
  internal           = var.alb_scheme == "internal"
  certificate_arn    = var.alb_certificate_arn
}

# -----------------------------------------------------------------------------
# 5. IAM Roles (EC2 Instance Profile and EB Service Role)
# -----------------------------------------------------------------------------
module "iam_roles" {
  source = "./modules/iam-roles"

  resource_prefix = var.resource_prefix
  app_name        = var.app_name
  environment     = var.environment
}

# -----------------------------------------------------------------------------
# 6. Elastic Beanstalk (App + Version from S3 + Environment with ALB & ASG)
# -----------------------------------------------------------------------------
module "elastic_beanstalk" {
  source = "./modules/elastic-beanstalk"

  resource_prefix             = var.resource_prefix
  app_name                    = var.app_name
  environment                 = var.environment
  eb_environment_name         = var.eb_environment_name
  eb_environment_cname_prefix = var.eb_environment_cname_prefix
  eb_environment_description  = var.eb_environment_description
  alb_scheme                  = var.alb_scheme
  eb_environment_variables    = var.eb_environment_variables
  solution_stack_name         = var.solution_stack_name
  instance_type               = var.instance_type
  min_instances               = var.min_instances
  max_instances               = var.max_instances
  root_volume_size            = var.root_volume_size

  # VPC wiring
  vpc_id             = local.vpc_id
  public_subnet_ids  = local.public_subnet_ids
  private_subnet_ids = local.private_subnet_ids

  # Custom security groups
  alb_security_group_ids      = [module.security_groups.alb_security_group_id]
  instance_security_group_ids = [module.security_groups.ec2_security_group_id]

  # IAM Roles
  ec2_instance_profile_name = module.iam_roles.ec2_instance_profile_name
  eb_service_role_arn       = module.iam_roles.eb_service_role_arn

  # Shared ALB — pass ARN if enabled, empty string if disabled (EB manages own)
  shared_alb_arn = var.enable_shared_alb ? module.alb[0].alb_arn : ""

  # S3 app source — managed by our S3 module
  app_s3_bucket     = module.s3.bucket_id
  app_s3_key        = module.s3.object_key     # Forms an implicit dependency on the aws_s3_object resource
  app_version_label = var.app_version_label

  # Logging
  log_retention_days = var.log_retention_days
}

# -----------------------------------------------------------------------------
# 7. CloudWatch Alarms (CPU, Unhealthy Hosts, Latency, EB Health)
# -----------------------------------------------------------------------------
module "cloudwatch" {
  source = "./modules/cloudwatch"

  resource_prefix         = var.resource_prefix
  environment             = var.environment
  autoscaling_group_name  = module.elastic_beanstalk.autoscaling_groups[0]
  alb_arn_suffix          = module.elastic_beanstalk.load_balancers[0]
  target_group_arn_suffix = var.target_group_arn_suffix
  eb_environment_name     = module.elastic_beanstalk.environment_name

  # Thresholds
  cpu_threshold     = var.cpu_threshold
  latency_threshold = var.latency_threshold

  # SNS
  create_sns_topic = var.create_sns_topic
  sns_topic_arn    = var.sns_topic_arn
  alarm_email      = var.alarm_email
}
