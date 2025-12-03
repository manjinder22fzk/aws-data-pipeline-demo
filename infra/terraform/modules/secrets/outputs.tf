output "config_secret_name" {
  value       = aws_secretsmanager_secret.pipeline_config.name
  description = "Name of the Secrets Manager secret used by the Lambda config loader"
}

output "config_secret_arn" {
  value       = aws_secretsmanager_secret.pipeline_config.arn
  description = "ARN of the Secrets Manager secret used for IAM policies"
}
