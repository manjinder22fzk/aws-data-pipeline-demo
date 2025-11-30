output "config_secret_name" {
  value = aws_secretsmanager_secret.pipeline_config.name
}

output "config_secret_arn" {
  value = aws_secretsmanager_secret.pipeline_config.arn
}
