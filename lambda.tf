variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "newrelic_account_id" {}
variable "insights_insert_key" {}

variable "aws_region" {
  default = "us-west-2"
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

// Allow Logging and X-Ray Access
resource "aws_iam_role_policy" "iam_role_policy_for_lambda" {
  name = "iam_role_policy_for_xray_collector"
  role = "${aws_iam_role.iam_for_lambda.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "xray:BatchGetTraces",
        "xray:GetTraceSummaries",
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ],
      "Effect": "Allow",
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_xray_collector"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "lambdium" {
  filename         = "lambda_function.zip"
  function_name    = "xray-collector"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  handler          = "index.handler"
  source_code_hash = "${base64sha256(file("lambda_function.zip"))}"
  runtime          = "nodejs6.10"
  timeout          = 20
  memory_size      = 128

  environment {
    variables = {
      DEBUG_ENV = "true"
      INSIGHTS_INSERT_KEY = "${var.insights_insert_key}"
      NEWRELIC_ACCOUNT_ID = "${var.newrelic_account_id}"
    }
  }
}
