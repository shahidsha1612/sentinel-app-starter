output "api_endpoint" {
  description = "Invoke URL for the Sentinel CUI documents API."
  value       = aws_apigatewayv2_api.http.api_endpoint
}

output "cui_bucket" {
  description = "S3 bucket storing CUI documents."
  value       = aws_s3_bucket.cui.bucket
}

output "meta_table" {
  description = "DynamoDB table storing document metadata."
  value       = aws_dynamodb_table.meta.name
}
