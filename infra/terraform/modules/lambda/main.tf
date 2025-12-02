locals {
  name_prefix   = "${var.project}-${var.environment}"
  function_name = "${local.name_prefix}-transform"
}

# CloudWatch log group (explicit, instead of relying on default)
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 14

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_sqs_queue" "dlq" {
  name = "${local.name_prefix}-lambda-dlq"

  # Should be >= Lambda timeout
  visibility_timeout_seconds = 120

  # Keep failed events for 14 days
  message_retention_seconds = 1209600

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# Count successful Lambda runs based on structured logs
resource "aws_cloudwatch_log_metric_filter" "lambda_success" {
  name           = "${local.name_prefix}-lambda-success"
  log_group_name = aws_cloudwatch_log_group.lambda_logs.name

  # Match JSON logs where event == "transform_completed" AND status == "success"
  pattern = "{ ($.event = \"transform_completed\") && ($.status = \"success\") }"

  metric_transformation {
    name      = "${local.name_prefix}-lambda-success-count"
    namespace = "Money96/DataPipeline"
    value     = "1"
  }
}

# Count failed Lambda runs based on structured logs
resource "aws_cloudwatch_log_metric_filter" "lambda_failure" {
  name           = "${local.name_prefix}-lambda-failure"
  log_group_name = aws_cloudwatch_log_group.lambda_logs.name

  pattern = "{ $.event = \"transform_failed\" }"

  metric_transformation {
    name      = "${local.name_prefix}-lambda-failure-count"
    namespace = "Money96/DataPipeline"
    value     = "1"
  }
}


resource "aws_lambda_function" "transform" {
  function_name = local.function_name
  role          = var.lambda_role_arn

  # For now: standard Python runtime
  runtime = "python3.12"
  handler = "handler.lambda_handler"

  # Code package
  filename         = var.lambda_package_path
  source_code_hash = filebase64sha256(var.lambda_package_path)

  timeout = 60
  memory_size = 256

  environment {
    variables = {
      CONFIG_SECRET_NAME    = var.config_secret_name
      RAW_BUCKET_NAME       = var.raw_bucket_name
      PROCESSED_BUCKET_NAME = var.processed_bucket_name
      APP_CONFIG_SECRET     = var.secret_name
      ENVIRONMENT           = var.environment
      PROJECT               = var.project
    }
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs
  ]

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_iam_policy_document" "lambda_secrets_access" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.config_secret_arn
    ]
  }
}

resource "aws_iam_policy" "lambda_secrets_policy" {
  name   = "${local.name_prefix}-lambda-secrets"
  policy = data.aws_iam_policy_document.lambda_secrets_access.json
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_attach" {
  role       = var.lambda_role_name
  policy_arn = aws_iam_policy.lambda_secrets_policy.arn
}

data "aws_iam_policy_document" "lambda_dlq_access" {
  statement {
    actions = [
      "sqs:SendMessage",
    ]

    resources = [
      aws_sqs_queue.dlq.arn,
    ]
  }
}

resource "aws_iam_policy" "lambda_dlq_policy" {
  name   = "${local.name_prefix}-lambda-dlq-access"
  policy = data.aws_iam_policy_document.lambda_dlq_access.json
}

resource "aws_iam_role_policy_attachment" "lambda_dlq_attach" {
  role       = var.lambda_role_name
  policy_arn = aws_iam_policy.lambda_dlq_policy.arn
}

# --- NEW: Async invoke config (retries, max event age) ---
resource "aws_lambda_function_event_invoke_config" "async" {
  function_name = aws_lambda_function.transform.function_name

  # How many times Lambda should retry on async failure
  maximum_retry_attempts       = 2

  # How long (in seconds) an event is retried before being considered failed
  maximum_event_age_in_seconds = 3600  # 1 hour
}