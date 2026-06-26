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
