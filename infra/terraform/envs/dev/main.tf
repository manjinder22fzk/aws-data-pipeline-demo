terraform {
  required_version = ">= 1.6.0"
  backend "s3" {
    bucket         = "money96-data-pipeline-tfstate"  # <== your bucket
    key            = "dev/terraform.tfstate"          # path inside the bucket
    region         = "us-east-1"                      # your region
    dynamodb_table = "money96-data-pipeline-tf-locks" # <== your table
    encrypt        = true
  }
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
  project     = "money96-data-pipeline"
  environment = "money96-dev"

  # In dev, it's okay to destroy buckets with objects
  force_destroy = true
}

module "iam" {
  source      = "../../modules/iam"
  project     = "money96-data-pipeline"
  environment = "money96-dev"

  raw_bucket_arn       = module.s3.raw_bucket_arn
  processed_bucket_arn = module.s3.processed_bucket_arn
}

module "lambda_transform" {
  source      = "../../modules/lambda"
  project     = "money96-data-pipeline"
  environment = "money96-dev"

  lambda_role_arn  = module.iam.lambda_exec_role_arn
  lambda_role_name = module.iam.lambda_exec_role_name # NEW

  raw_bucket_name       = module.s3.raw_bucket_id
  processed_bucket_name = module.s3.processed_bucket_id

  secret_name         = "money96-data-pipeline/dev/app-config" # we'll create later
  lambda_package_path = var.lambda_package_path
  config_secret_name  = module.secrets.config_secret_name
  config_secret_arn   = module.secrets.config_secret_arn
}

module "eventbridge" {
  source      = "../../modules/eventbridge"
  project     = "money96-data-pipeline"
  environment = "money96-dev"

  raw_bucket_name     = module.s3.raw_bucket_id
  lambda_function_arn = module.lambda_transform.lambda_function_arn
}


module "secrets" {
  source = "../../modules/secrets"

  project               = "money96-data-pipeline"
  environment           = "money96-dev"
  raw_bucket_name       = module.s3.raw_bucket_id
  processed_bucket_name = module.s3.processed_bucket_id
}

