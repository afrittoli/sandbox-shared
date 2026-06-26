module "platform_role" {
  source   = "./modules/platform-role"
  for_each = var.platforms

  platform_name       = each.key
  repo_name           = each.value.repo_name
  github_org          = var.github_org
  oidc_provider_arn   = aws_iam_openid_connect_provider.github_actions.arn
  bucket_arn          = aws_s3_bucket.artifacts.arn
  shared_workflow_ref = var.shared_workflow_ref
}
