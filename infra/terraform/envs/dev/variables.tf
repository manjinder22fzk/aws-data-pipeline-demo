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
