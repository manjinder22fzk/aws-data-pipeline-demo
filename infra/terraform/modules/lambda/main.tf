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
