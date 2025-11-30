output "developers_group_name" {
  description = "IAM group name for developers"
  value       = aws_iam_group.developers.name
}

output "dev_user_name" {
  description = "Example dev IAM user name"
  value       = aws_iam_user.dev_user.name
}

output "lambda_exec_role_arn" {
  description = "Execution role ARN for the transform Lambda"
  value       = aws_iam_role.lambda_exec_role.arn
}

output "lambda_exec_role_name" {
  value = aws_iam_role.lambda_exec_role.name
}