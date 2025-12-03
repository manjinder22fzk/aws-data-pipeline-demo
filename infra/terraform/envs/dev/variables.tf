variable "region" {
  description = "AWS region for dev environment"
  type        = string
  default     = "us-east-1"
}

# variable "aws_profile" {
#   description = "AWS CLI profile for dev environment"
#   type        = string
#   default     = "dev"
# }

variable "lambda_package_path" {
  description = "Local path to the Lambda zip for dev"
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

variable "aws_profile" { # Not actually used, cam be deleted as well since it is local only
  type        = string
  description = "AWS CLI profile name"
  default     = "dev" # override in stage/prod if needed
}


