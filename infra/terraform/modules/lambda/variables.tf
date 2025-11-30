variable "project" {
  description = "Project name prefix (e.g. data-pipeline)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, stage, prod)"
  type        = string
}

variable "lambda_role_arn" {
  description = "IAM role ARN for Lambda execution"
  type        = string
}

variable "raw_bucket_name" {
  description = "Name of the raw S3 bucket"
  type        = string
}

variable "processed_bucket_name" {
  description = "Name of the processed S3 bucket"
  type        = string
}

variable "secret_name" {
  description = "Name of the secret in Secrets Manager used by Lambda"
  type        = string
  default     = "data-pipeline/app-config" # we can adjust later
}

variable "lambda_package_path" {
  description = "Path to the built Lambda deployment package (.zip)"
  type        = string
}
