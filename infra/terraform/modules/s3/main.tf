locals {
  name_prefix = "${var.project}-${var.environment}"
}

########################################
# Raw bucket
########################################

resource "aws_s3_bucket" "raw" {
  bucket = "${local.name_prefix}-raw"

  force_destroy = var.force_destroy

  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "raw-landing-zone"
  }
}

resource "aws_s3_bucket_versioning" "raw_versioning" {
  bucket = aws_s3_bucket.raw.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw_encryption" {
  bucket = aws_s3_bucket.raw.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "raw_public_access_block" {
  bucket = aws_s3_bucket.raw.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

########################################
# Processed bucket
########################################

resource "aws_s3_bucket" "processed" {
  bucket = "${local.name_prefix}-processed"

  force_destroy = var.force_destroy

  tags = {
    Project     = var.project
    Environment = var.environment
    Purpose     = "processed-zone"
  }
}

resource "aws_s3_bucket_versioning" "processed_versioning" {
  bucket = aws_s3_bucket.processed.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed_encryption" {
  bucket = aws_s3_bucket.processed.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "processed_public_access_block" {
  bucket = aws_s3_bucket.processed.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "raw_notifications" {
  bucket = aws_s3_bucket.raw.id

  eventbridge  = true

  depends_on = [
    aws_s3_bucket_public_access_block.raw_public_access_block
  ]
}
