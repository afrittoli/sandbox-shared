output "platform1_role_arn" {
  description = "ARN of the IAM role for platform1 (afrittoli/sandbox)"
  value       = aws_iam_role.platform1.arn
}

output "platform2_role_arn" {
  description = "ARN of the IAM role for platform2 (afrittoli/sandbox-2)"
  value       = aws_iam_role.platform2.arn
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
