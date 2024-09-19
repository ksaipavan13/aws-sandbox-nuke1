# Provider block to specify AWS region
provider "aws" {
  region = "us-east-1"  # Update with your region
}

# IAM Role for Lambda execution
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM policy for Lambda permissions
resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "ec2:TerminateInstances",   # Required for Nuke Sandbox
          "ec2:DescribeInstances",    # Required for Nuke Sandbox
          "ec2:StopInstances",        # Optional, if you want to stop instances instead of terminating
          "s3:DeleteBucket",          # If you plan to delete S3 buckets
          "s3:DeleteObject",          # If you plan to delete S3 objects
          "iam:ListUsers",            # Required for Deactivating/Reactivating Users
          "iam:ListAccessKeys",       # Required for Deactivating/Reactivating Users
          "iam:UpdateAccessKey",      # Required for Deactivating/Reactivating Users
          "iam:DeleteLoginProfile",   # Required for Deactivating Users
          "iam:CreateLoginProfile",   # Required for Reactivating Users
          "logs:CreateLogGroup",      # Permission to create CloudWatch log groups
          "logs:CreateLogStream",     # Permission to create CloudWatch log streams
          "logs:PutLogEvents"         # Permission to put logs into CloudWatch
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

        

# Attach policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda function to nuke AWS sandbox (terminate instances, delete resources)
resource "aws_lambda_function" "nuke_sandbox" {
  filename      = "nuke_sandbox_lambda.zip"
  function_name = "nuke_sandbox"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "nuke_sandbox_lambda.lambda_handler"   # Updated handler
  runtime       = "python3.9"
  timeout       = 30
  memory_size   = 128
}

# Lambda function to deactivate IAM users
resource "aws_lambda_function" "deactivate_users" {
  filename      = "deactivate_users_lambda.zip"
  function_name = "deactivate_users"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "deactivate_users_lambda.lambda_handler"   # Updated handler
  runtime       = "python3.9"
  timeout       = 30
  memory_size   = 128
}

# Lambda function to reactivate IAM users
resource "aws_lambda_function" "reactivate_users" {
  filename      = "reactivate_users_lambda.zip"
  function_name = "reactivate_users"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "reactivate_users_lambda.lambda_handler"   # Updated handler
  runtime       = "python3.9"
  timeout       = 30
  memory_size   = 128
}

# Event rule to trigger nuke_sandbox and deactivate_users at 6 PM IST
resource "aws_cloudwatch_event_rule" "nuke_and_deactivate" {
  name                = "nuke_and_deactivate"
  schedule_expression = "cron(30 12 * * ? *)"  # 6 PM IST (12:30 UTC)
}

# Target for nuke_sandbox Lambda function
resource "aws_cloudwatch_event_target" "nuke_target" {
  rule      = aws_cloudwatch_event_rule.nuke_and_deactivate.name
  target_id = "nuke_sandbox"
  arn       = aws_lambda_function.nuke_sandbox.arn
}

# Target for deactivate_users Lambda function
resource "aws_cloudwatch_event_target" "deactivate_target" {
  rule      = aws_cloudwatch_event_rule.nuke_and_deactivate.name
  target_id = "deactivate_users"
  arn       = aws_lambda_function.deactivate_users.arn
}

# Event rule to trigger reactivation at 10 AM IST
resource "aws_cloudwatch_event_rule" "reactivate" {
  name                = "reactivate_users"
  schedule_expression = "cron(30 4 * * ? *)"  # 10 AM IST (4:30 UTC)
}

# Target for reactivate_users Lambda function
resource "aws_cloudwatch_event_target" "reactivate_target" {
  rule      = aws_cloudwatch_event_rule.reactivate.name
  target_id = "reactivate_users"
  arn       = aws_lambda_function.reactivate_users.arn
}

