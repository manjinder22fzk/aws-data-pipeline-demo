locals {
  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_cloudwatch_event_rule" "s3_object_created_rule" {
  name        = "${local.name_prefix}-s3-object-created"
  description = "Trigger Lambda when a new object is created in the raw bucket"

  event_pattern = jsonencode({
    "source": ["aws.s3"],
    "detail-type": ["Object Created"],
    "detail": {
      "bucket": {
        "name": [var.raw_bucket_name]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.s3_object_created_rule.name
  target_id = "lambda-transform"
  arn       = var.lambda_function_arn

  dead_letter_config {
    arn = aws_sqs_queue.lambda_dlq.arn
  }
}

resource "aws_lambda_permission" "allow_eventbridge_invoke" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.s3_object_created_rule.arn
}

resource "aws_sqs_queue" "lambda_dlq" {
  name = "${var.project}-${var.environment}-lambda-dlq"

  # Optional: keep messages for 14 days so you can debug
  message_retention_seconds = 14 * 24 * 60 * 60
}

data "aws_iam_policy_document" "lambda_dlq_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "sqs:SendMessage",
    ]

    resources = [
      aws_sqs_queue.lambda_dlq.arn,
    ]
  }
}

resource "aws_sqs_queue_policy" "lambda_dlq_policy" {
  queue_url = aws_sqs_queue.lambda_dlq.id
  policy    = data.aws_iam_policy_document.lambda_dlq_policy.json
}
