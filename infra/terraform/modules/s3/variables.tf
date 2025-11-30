variable "project" {
  description = "Project name prefix (e.g. data-pipeline)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, stage, prod)"
  type        = string
}

variable "force_destroy" {
  description = "Allow S3 buckets to be destroyed even if they contain objects"
  type        = bool
  default     = false
}
