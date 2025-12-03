# Later will output bucket names, lambda names etc.
output "raw_bucket_name" {
  description = "Raw bucket name for dev"
  value       = module.s3.raw_bucket_id
}

output "processed_bucket_name" {
  description = "Processed bucket name for dev"
  value       = module.s3.processed_bucket_id
}

output "lambda_function_name" {
  description = "Lambda transform function name for dev"
  value       = module.lambda_transform.lambda_function_name
}
