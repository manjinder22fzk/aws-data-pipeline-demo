locals {
  name_prefix = "${var.project}-${var.environment}"
}

########################################
# Developer group + example user
########################################

resource "aws_iam_group" "developers" {
  name = "${local.name_prefix}-developers"
}

# Example user (for learning). In real companies this is usually SSO instead.
resource "aws_iam_user" "dev_user" {
  name = "${local.name_prefix}-dev-user"
}

resource "aws_iam_user_group_membership" "dev_user_membership" {
  user = aws_iam_user.dev_user.name

  groups = [
    aws_iam_group.developers.name
  ]
}

########################################
# Lambda execution role
########################################

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name               = "${local.name_prefix}-lambda-transform-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Basic execution policy: logs + secrets
data "aws_iam_policy_document" "lambda_exec_policy" {
  statement {
    sid     = "AllowCloudWatchLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid = "AllowReadSecretsManager"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = ["*"] # later we can restrict to specific secret ARNs
  }
}

resource "aws_iam_policy" "lambda_exec_policy" {
  name        = "${local.name_prefix}-lambda-exec-policy"
  description = "Base execution policy for Lambda (logs + secrets)"
  policy      = data.aws_iam_policy_document.lambda_exec_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_exec_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_exec_policy.arn
}
