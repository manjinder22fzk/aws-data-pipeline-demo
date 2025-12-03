terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  # profile = var.aws_profile
}


module "s3" {
  source      = "../../modules/s3"
  project     = var.project
  environment = var.environment

  # In dev, it's okay to destroy buckets with objects
  force_destroy = true
}

module "iam" {
  source      = "../../modules/iam"
  project     = var.project
  environment = var.environment

  raw_bucket_arn       = module.s3.raw_bucket_arn
  processed_bucket_arn = module.s3.processed_bucket_arn
}

module "lambda_transform" {
  source      = "../../modules/lambda"
  project     = var.project
  environment = var.environment

  lambda_role_arn  = module.iam.lambda_exec_role_arn
  lambda_role_name = module.iam.lambda_exec_role_name # NEW

  raw_bucket_name       = module.s3.raw_bucket_id
  processed_bucket_name = module.s3.processed_bucket_id

  secret_name         = "money96-data-pipeline/dev/app-config" # old : can be delete dnow or later
  lambda_package_path = var.lambda_package_path
  config_secret_name  = module.secrets.config_secret_name
  config_secret_arn   = module.secrets.config_secret_arn
}

module "eventbridge" {
  source      = "../../modules/eventbridge"
  project     = var.project
  environment = var.environment

  raw_bucket_name     = module.s3.raw_bucket_id
  lambda_function_arn = module.lambda_transform.lambda_function_arn
}

# (Optional) re-expose DLQ for convenience
output "lambda_dlq_url" {
  value = module.eventbridge.lambda_dlq_url
}

module "secrets" {
  source = "../../modules/secrets"

  project               = var.project
  environment           = var.environment
  raw_bucket_name       = module.s3.raw_bucket_id
  processed_bucket_name = module.s3.processed_bucket_id
}

module "alerts" {
  source = "../../modules/alerts"

  project     = var.project
  environment = var.environment

  lambda_function_name = module.lambda_transform.lambda_function_name

  alarm_email = "manjindersinghfzk@gmail.com"
}


