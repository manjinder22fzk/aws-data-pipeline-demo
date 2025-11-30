output "rule_name" {
  description = "Name of the EventBridge rule for S3 object created"
  value       = aws_cloudwatch_event_rule.s3_object_created_rule.name
}
