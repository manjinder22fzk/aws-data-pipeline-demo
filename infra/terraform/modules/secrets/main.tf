terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  name_prefix     = "${var.project}-${var.environment}"
  config_secret_name = "${local.name_prefix}-config"
}

resource "aws_secretsmanager_secret" "pipeline_config" {
  name        = local.config_secret_name
  description = "Config for ${local.name_prefix} data pipeline"
}

# For dev, we’re okay storing a dummy value via Terraform.
# For prod, you’d usually rotate/override this manually or via CI.
resource "aws_secretsmanager_secret_version" "pipeline_config_value" {
  secret_id     = aws_secretsmanager_secret.pipeline_config.id
  secret_string = jsonencode({
    project          = var.project
    environment      = var.environment
    raw_bucket       = var.raw_bucket_name
    processed_bucket = var.processed_bucket_name
    processed_prefix = "processed/"
    min_amount_filter = 10.0
    country_filter    = "CA"
  })
}
