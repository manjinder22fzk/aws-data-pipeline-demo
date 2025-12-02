output "rule_name" {
  description = "Name of the EventBridge rule for S3 object created"
  value       = aws_cloudwatch_event_rule.s3_object_created_rule.name
}

output "lambda_dlq_arn" {
  value = aws_sqs_queue.lambda_dlq.arn
}

output "lambda_dlq_url" {
  value = aws_sqs_queue.lambda_dlq.id
}
