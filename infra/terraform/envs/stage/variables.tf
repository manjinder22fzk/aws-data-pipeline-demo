variable "region" {
  description = "AWS region for stage environment"
  type        = string
  default     = "us-east-1"
}

# variable "aws_profile" {
#   description = "AWS CLI profile for dev environment"
#   type        = string
#   default     = "dev"
# }

variable "lambda_package_path" {
  description = "Local path to the Lambda zip for stage"
  type        = string
  default     = "../../../../app/lambda_transform/dist/lambda.zip"
}

variable "project" {
  type        = string
  description = "Project identifier prefix"
  default     = "money96-data-pipeline"
}

variable "environment" {
  type        = string
  description = "Environment name (money96-dev / money96-stage / money96-prod)"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile name"
  default     = "dev"
}


