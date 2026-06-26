variable "platform_name" {
  description = "Platform identifier (used in role name, tags, and S3 prefix)"
  type        = string
}

variable "repo_name" {
  description = "GitHub repository name (without org) that can assume this role"
  type        = string
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the S3 bucket for artifacts"
  type        = string
}

variable "shared_workflow_ref" {
  description = "The shared reusable workflow ref to enforce in the trust policy"
  type        = string
}
