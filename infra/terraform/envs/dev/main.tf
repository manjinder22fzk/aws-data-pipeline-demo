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

module "iam" {
  source      = "../../modules/iam"
  project     = "data-pipeline"
  environment = "dev"
}

# Later:
# - call s3, lambda, iam, eventbridge modules
# - pass in environment-specific variables
