# Terraform Elastic Beanstalk — Multi-Environment Deployment

Reusable Terraform modules for deploying **AWS Elastic Beanstalk** environments with ALB, Auto Scaling, CloudWatch monitoring, and OIDC-based keyless authentication.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Azure DevOps Pipeline             │
│   develop → Dev  │  release/* → QA  │  main → Prod  │
└──────────┬──────────────┬──────────────┬────────────┘
           │ OIDC         │ OIDC         │ OIDC
           ▼              ▼              ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  AWS Dev Acc │  │  AWS QA Acc  │  │ AWS Prod Acc │
│  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │
│  │  VPC   │  │  │  │  VPC   │  │  │  │  VPC   │  │
│  │  EB    │  │  │  │  EB    │  │  │  │  EB    │  │
│  │  CW    │  │  │  │  CW    │  │  │  │  CW    │  │
│  └────────┘  │  │  └────────┘  │  │  └────────┘  │
└──────────────┘  └──────────────┘  └──────────────┘
```

## Modules

| Module              | Description                                                |
|---------------------|------------------------------------------------------------|
| `modules/oidc`      | IAM OIDC identity provider + deploy role for keyless auth  |
| `modules/vpc`       | VPC with 2 public + 2 private subnets, IGW, NAT Gateway   |
| `modules/elastic-beanstalk` | EB Application, Version (from S3), Environment with ALB & ASG |
| `modules/cloudwatch`| CloudWatch Alarms (CPU, Unhealthy Hosts, Latency, EB Health) + SNS |

## Lifecycle Protection

All stateful resources include `lifecycle { prevent_destroy = true }` to prevent accidental deletion during `terraform apply`. Protected resources include:

- **VPC**: VPC, Subnets, Internet Gateway, NAT Gateway, Elastic IP
- **Elastic Beanstalk**: Application, Environment, IAM Roles, Instance Profile
- **OIDC**: Identity Provider, Deploy Role
- **CloudWatch**: SNS Topic, all metric alarms

> **⚠️ To intentionally destroy resources**, you must first set `prevent_destroy = false` in the relevant module, run `terraform apply`, then run `terraform destroy`.

---

## Prerequisites

1. **Terraform** >= 1.5.0
2. **Azure DevOps** account with the [Terraform extension](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks) installed
3. **AWS accounts** for each environment (dev, qa, prod)
4. **S3 bucket** for Terraform remote state (one per environment or shared with key prefix)
5. **DynamoDB table** for state locking (optional but recommended)

---

## Azure DevOps Pipeline Setup

### 1. Create AWS Service Connections (OIDC)

In Azure DevOps **Project Settings → Service connections**:

1. Click **New service connection** → Select **AWS**
2. Choose **Workload Identity Federation (OIDC)**
3. Create one service connection per environment:
   - `aws-dev-oidc` → Dev AWS Account
   - `aws-qa-oidc` → QA AWS Account
   - `aws-prod-oidc` → Prod AWS Account
4. Note the **Issuer URL** and **Subject** from each connection

### 2. Update `.tfvars` Files

Replace the placeholders in each environment file:

```hcl
# environments/dev.tfvars
oidc_provider_url     = "https://vstoken.dev.azure.com/<your-org-id>"
oidc_allowed_subjects = ["sc://<org>/<project>/aws-dev-oidc"]
aws_account_id        = "<your-dev-account-id>"
```

### 3. Configure Pipeline Variables

Set the following pipeline variable (or use a variable group):

| Variable           | Description                         |
|--------------------|-------------------------------------|
| `TF_STATE_BUCKET`  | S3 bucket name for Terraform state  |

### 4. Set Up Approval Gates

In Azure DevOps **Pipelines → Environments**:

1. Create environments: `dev`, `qa`, `prod`
2. Add **Approvals and checks** on `qa` and `prod` environments
3. Assign approvers for production deployments

### 5. Import Pipeline

1. Go to **Pipelines → New Pipeline**
2. Select your repository
3. Choose **Existing Azure Pipelines YAML file**
4. Select `/Terraform-EBStalk/azure-pipelines.yml`

---

## Pipeline Flow

```
develop branch push
    └── Dev Stage (auto-deploy)
            └── QA Stage (manual approval)
                    └── Prod Stage (manual approval)

main branch push
    └── Dev Stage (auto-deploy)
            └── QA Stage (manual approval)
                    └── Prod Stage (manual approval)

release/* branch push
    └── Dev Stage (auto-deploy)
            └── QA Stage (manual approval)
```

---

## Local Usage

```bash
# Initialize
terraform init

# Plan for a specific environment
terraform plan -var-file="environments/dev.tfvars"

# Apply
terraform apply -var-file="environments/dev.tfvars"
```

---

## Project Structure

```
Terraform-EBStalk/
├── azure-pipelines.yml            # Multi-stage pipeline definition
├── templates/
│   └── terraform-job.yml          # Reusable Terraform job template
├── main.tf                        # Root module — orchestrates sub-modules
├── variables.tf                   # Root variable declarations
├── outputs.tf                     # Root outputs
├── providers.tf                   # AWS provider with OIDC auth
├── environments/
│   ├── dev.tfvars                 # Dev environment config
│   ├── qa.tfvars                  # QA environment config
│   └── prod.tfvars                # Prod environment config
└── modules/
    ├── oidc/                      # OIDC identity provider + role
    ├── vpc/                       # VPC, subnets, gateways
    ├── elastic-beanstalk/         # EB app, version, environment
    └── cloudwatch/                # Alarms + SNS notifications
```
