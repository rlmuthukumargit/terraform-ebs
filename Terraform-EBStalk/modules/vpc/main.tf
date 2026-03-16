################################################################################
# VPC Module
# Creates a VPC with public and private subnets across 3 AZs.
################################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name        = "${var.resource_prefix}-vpc"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Public Subnets (one per AZ for ALB)
# -----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name        = "${var.resource_prefix}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Tier        = "public"
  }
}

# -----------------------------------------------------------------------------
# Private Subnets (one per AZ for EC2 instances)
# -----------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name        = "${var.resource_prefix}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Tier        = "private"
  }
}
