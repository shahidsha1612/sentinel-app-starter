# =============================================================================
# Sentinel — CUI document intake  (INTENTIONALLY NON-COMPLIANT STARTER)
# -----------------------------------------------------------------------------
# A defense contractor's file-drop API for Controlled Unclassified Information
# (CUI). It works, and it is deliberately non-compliant with CMMC Level 2 /
# NIST SP 800-171. Do NOT rewrite the app — ADD a governance baseline, policy-
# as-code, a CI gate, an OSCAL component, and an evidence chain so the flaws in
# GAPS.md are detected and remediated.
#
# Every flaw is tagged with its gap id (SN-0x). Leave the tags in place.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  name = "sentinel-${var.env}"
}

# -----------------------------------------------------------------------------
# CUI document store.
# SN-01: objects are NOT encrypted at rest (no customer-managed key).
# SN-02: bucket is world-readable (public-read ACL, no public access block).
# SN-06: no object-level CUI marking / no integrity (versioning off).
# SN-09: no Object Lock — audit/evidence records are mutable.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "cui" {
  bucket        = "${local.name}-cui"
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "cui" {
  bucket = aws_s3_bucket.cui.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cui" {
  depends_on = [aws_s3_bucket_ownership_controls.cui]
  bucket     = aws_s3_bucket.cui.id
  acl        = "public-read" # SN-02: CUI is publicly readable.
}

# SN-02: public access is deliberately not blocked on this bucket.
# SN-01: encryption-at-rest is deliberately not configured on this bucket.

# -----------------------------------------------------------------------------
# Metadata table.
# SN-01: no server-side encryption / no CMK.
# -----------------------------------------------------------------------------
resource "aws_dynamodb_table" "meta" {
  name         = "${local.name}-meta"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "doc_id"

  attribute {
    name = "doc_id"
    type = "S"
  }
  # SN-01: encryption-at-rest is intentionally not configured on this table.
}

# -----------------------------------------------------------------------------
# Lambda role.
# SN-07: wildcard "*"/"*" permissions (no least privilege).
# -----------------------------------------------------------------------------
resource "aws_iam_role" "lambda" {
  name = "${local.name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_admin" {
  name = "${local.name}-lambda-admin"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*" # SN-07: wildcard action.
      Resource = "*" # SN-07: wildcard resource.
    }]
  })
}

# -----------------------------------------------------------------------------
# Document handler.
# SN-10: hardcoded plaintext shared secret in environment.
# -----------------------------------------------------------------------------
data "archive_file" "handler" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/build/handler.zip"
}

resource "aws_lambda_function" "docs" {
  function_name    = "${local.name}-docs"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  handler          = "handler.handler"
  filename         = data.archive_file.handler.output_path
  source_code_hash = data.archive_file.handler.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      CUI_BUCKET = aws_s3_bucket.cui.bucket
      META_TABLE = aws_dynamodb_table.meta.name
      # SN-10: hardcoded plaintext secret.
      UPLOAD_SHARED_SECRET = "sentinel-shared-secret-do-not-hardcode"
    }
  }
}

# -----------------------------------------------------------------------------
# HTTP API.
# SN-04: plain HTTP API with no enforced transport-security minimum.
# SN-05: no authorizer / no MFA — anyone can upload or fetch CUI.
# SN-03: no access logging on the stage.
# SN-08: no WAF / no boundary protection.
# -----------------------------------------------------------------------------
resource "aws_apigatewayv2_api" "http" {
  name          = "${local.name}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "docs" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.docs.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "upload" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /documents"
  target    = "integrations/${aws_apigatewayv2_integration.docs.id}"
  # SN-05: authorization_type defaults to NONE.
}

resource "aws_apigatewayv2_route" "fetch" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /documents/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.docs.id}"
  # SN-05: authorization_type defaults to NONE.
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
  # SN-03: no access_log_settings block.
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGWInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.docs.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

# SN-03 / SN-09: NOTE — no aws_cloudtrail, no immutable audit vault, no Object
# Lock anywhere in the starter. Add them in your baseline.
