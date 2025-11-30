variable "project" {
  description = "Project name prefix (e.g. data-pipeline)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, stage, prod)"
  type        = string
}

variable "raw_bucket_arn" {
  description = "ARN of the raw S3 bucket"
  type        = string
}

variable "processed_bucket_arn" {
  description = "ARN of the processed S3 bucket"
  type        = string
}
