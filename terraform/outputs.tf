output "platform_role_arns" {
  description = "Map of platform name to IAM role ARN"
  value       = { for k, v in module.platform_role : k => v.role_arn }
}

output "bucket_name" {
  description = "Name of the S3 bucket for build artifacts"
  value       = aws_s3_bucket.artifacts.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket for build artifacts"
  value       = aws_s3_bucket.artifacts.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}
