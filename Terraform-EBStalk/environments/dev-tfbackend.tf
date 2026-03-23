terraform {
  backend "s3" {
    bucket = "tss-ebstalk-terraform-backend"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
    #dynamodb_table = "tss-dev-table"
    encrypt = true
  }
}
