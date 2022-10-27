variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.36.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region     = var.aws_region
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}


data "archive_file" "lambda_[LAMBDA TEMPLATE]" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/dist/[LAMBDA TEMPLATE].zip"
}

resource "aws_s3_object" "lambda_[LAMBDA TEMPLATE]" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "[LAMBDA TEMPLATE].zip"
  source = data.archive_file.lambda_[LAMBDA TEMPLATE].output_path
}

resource "random_pet" "lambda_bucket_name" {
  prefix = "[LAMBDA TEMPLATE]"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

resource "aws_lambda_function" "lambda_[LAMBDA TEMPLATE]" {
  function_name = "[LAMBDA TEMPLATE]"
  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_[LAMBDA TEMPLATE].key
  runtime = "nodejs14.x"
  handler = "index.handler"
  source_code_hash = data.archive_file.lambda_[LAMBDA TEMPLATE].output_base64sha256
  role = aws_iam_role.lambda_exec.arn
  environment {
    variables = {
    }
  }
}

resource "aws_cloudwatch_log_group" "[LAMBDA TEMPLATE]" {
  name = "/aws/lambda/${aws_lambda_function.lambda_[LAMBDA TEMPLATE].function_name}"
  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "[LAMBDA TEMPLATE]-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
