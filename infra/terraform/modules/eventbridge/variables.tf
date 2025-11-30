variable "project" {
  description = "Project name prefix (e.g. data-pipeline)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, stage, prod)"
  type        = string
}

variable "raw_bucket_name" {
  description = "Name of the raw S3 bucket to listen to"
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to invoke"
  type        = string
}
