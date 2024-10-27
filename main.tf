provider "aws" {
  region = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}
resource "random_pet" "bucket_name" {
  length    = 2
  separator = "-"
}
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.service_name}-${random_pet.bucket_name.id}"

  tags = {
    Service     = "${var.service_name}"
    Environment = "${var.environment}"
    Name        = "${var.service_name}-${var.environment}-s3-bucket"
    Terraform   = "true"
  }
}
resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
data "aws_iam_policy_document" "lambda_role_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
  
}
resource "aws_iam_role" "lambda_execution_role"{
  name="${var.service_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_role_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "service_lambda_role_basic_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
data "aws_iam_policy_document" "s3_access_policy_document" {
  statement {
    actions   = ["s3:putObject", "s3:getObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
  }
}