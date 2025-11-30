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
  region  = var.region
  profile = var.aws_profile
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

  lambda_role_arn      = module.iam.lambda_exec_role_arn
  raw_bucket_name      = module.s3.raw_bucket_id
  processed_bucket_name = module.s3.processed_bucket_id
  secret_name          = "money96-data-pipeline/dev/app-config" # we'll create later

  lambda_package_path  = var.lambda_package_path
}



# Later:
# - call s3, lambda, iam, eventbridge modules
# - pass in environment-specific variables
