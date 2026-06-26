variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for out-of-tree platform artifacts"
  type        = string
  default     = "afrittoli-rfc0055-poc"
}

variable "github_org" {
  description = "GitHub organization for OIDC federation"
  type        = string
  default     = "afrittoli"
}

variable "shared_workflow_ref" {
  description = "The shared reusable workflow ref to enforce in IAM trust policies"
  type        = string
  default     = "afrittoli/sandbox-shared/.github/workflows/shared-build.yml@refs/heads/main"
}

variable "platforms" {
  description = "Map of platform configurations. Key is the platform name, value contains the source repo."
  type = map(object({
    repo_name = string
  }))
  default = {
    platform1 = { repo_name = "sandbox" }
    platform2 = { repo_name = "sandbox-2" }
  }
}