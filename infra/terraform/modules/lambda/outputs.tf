output "lambda_function_name" {
  description = "Name of the transform Lambda function"
  value       = aws_lambda_function.transform.function_name
}

output "lambda_function_arn" {
  description = "ARN of the transform Lambda function"
  value       = aws_lambda_function.transform.arn
}
