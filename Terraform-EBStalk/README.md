# AWS Elastic Beanstalk — Terraform Infrastructure

Reusable Terraform modules for deploying a **highly-available Elastic Beanstalk** application across **dev**, **qa**, and **prod** environments in **separate AWS accounts**, authenticated via **OIDC** (no static access keys).

## Architecture

| Feature | Detail |
|---|---|
| **Load Balancer** | Application Load Balancer (ALB) |
| **Auto Scaling** | ASG with configurable min/max per environment |
| **High Availability** | 2 AZs, private subnets for instances, public subnets for ALB |
| **Deployment** | JAR/WAR fetched from S3, rolling updates with zero downtime |
| **Authentication** | OIDC provider (GitHub Actions) → AssumeRoleWithWebIdentity |
| **Monitoring** | CloudWatch alarms for CPU, latency, unhealthy hosts, EB health |
| **Notifications** | SNS topic with optional email subscription |

## Project Structure

```
├── modules/
│   ├── oidc/               # IAM OIDC Identity Provider + deploy role
│   ├── vpc/                # 2-AZ VPC with public/private subnets
│   ├── elastic-beanstalk/  # EB app, S3 app version, ALB environment
│   └── cloudwatch/         # CloudWatch alarms + SNS notifications
├── environments/
│   ├── dev.tfvars          # Dev account config
│   ├── qa.tfvars           # QA account config
│   └── prod.tfvars         # Prod account config
├── main.tf                 # Root module (wires everything together)
├── variables.tf            # All variable declarations
├── outputs.tf              # All outputs
└── providers.tf            # AWS provider with OIDC auth
```

## Prerequisites

1. **Terraform** >= 1.5.0
2. **AWS accounts** — one per environment (dev, qa, prod)
3. **S3 bucket** — per account, containing your application JAR/WAR
4. **OIDC provider** — configured in your CI/CD (e.g., GitHub Actions)

## Usage

### 1. Configure Environment Variables

Update the placeholder values in `environments/*.tfvars`:

- `aws_account_id` — your AWS account ID for each environment
- `oidc_allowed_subjects` — your GitHub repo/branch (e.g., `repo:my-org/my-repo:ref:refs/heads/main`)
- `app_s3_bucket` / `app_s3_key` — S3 location of your JAR/WAR
- `alarm_email` — email for CloudWatch alarm notifications

### 2. Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Deploy to dev
terraform plan  -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# Deploy to QA
terraform plan  -var-file="environments/qa.tfvars"
terraform apply -var-file="environments/qa.tfvars"

# Deploy to prod
terraform plan  -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

### 3. GitHub Actions Example

```yaml
name: Deploy to AWS
on:
  push:
    branches: [main]

permissions:
  id-token: write   # Required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::333333333333:role/prod-oidc-deploy-role
          aws-region: us-east-1

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init & Apply
        run: |
          terraform init
          terraform apply -auto-approve -var-file="environments/prod.tfvars"
```

## Updating the Application

To deploy a new version:

1. Upload the new JAR/WAR to S3
2. Update `app_s3_key` and `app_version_label` in the appropriate `.tfvars`
3. Run `terraform apply -var-file="environments/<env>.tfvars"`

## Destroying Infrastructure

```bash
terraform destroy -var-file="environments/dev.tfvars"
```

## Environment Sizing

| | Dev | QA | Prod |
|---|---|---|---|
| **Instance Type** | t3.micro | t3.small | t3.medium |
| **ASG Min/Max** | 1 / 2 | 2 / 4 | 2 / 6 |
| **CPU Alarm** | 85% | 80% | 70% |
| **Latency Alarm** | 2.0s | 1.5s | 1.0s |
| **Log Retention** | 14 days | 30 days | 90 days |
