output "raw_bucket_id" {
  description = "ID (name) of the raw S3 bucket"
  value       = aws_s3_bucket.raw.id
}

output "raw_bucket_arn" {
  description = "ARN of the raw S3 bucket"
  value       = aws_s3_bucket.raw.arn
}

output "processed_bucket_id" {
  description = "ID (name) of the processed S3 bucket"
  value       = aws_s3_bucket.processed.id
}

output "processed_bucket_arn" {
  description = "ARN of the processed S3 bucket"
  value       = aws_s3_bucket.processed.arn
}
