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
}

resource "aws_lambda_permission" "allow_eventbridge_invoke" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.s3_object_created_rule.arn
}
