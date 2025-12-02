variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "lambda_function_name" {
  type = string
}

variable "alarm_email" {
  type        = string
  description = "Email address to receive alerts"
}
