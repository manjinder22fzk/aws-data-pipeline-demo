variable "region" {
  description = "AWS region for dev environment"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile for dev environment"
  type        = string
  default     = "dev"
}

variable "lambda_package_path" {
  description = "Local path to the Lambda zip for dev"
  type        = string
  default     = "../../../../app/lambda_transform/dist/lambda.zip"
}

