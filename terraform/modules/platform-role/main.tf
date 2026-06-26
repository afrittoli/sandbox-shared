data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.repo_name}:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:job_workflow_ref"
      values   = [var.shared_workflow_ref]
    }
  }
}

data "aws_iam_policy_document" "permissions" {
  statement {
    sid = "AllowPrefixedObjectAccess"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]

    resources = [
      "${var.bucket_arn}/${var.platform_name}/*",
    ]
  }

  statement {
    sid = "AllowListBucketWithPrefix"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      var.bucket_arn,
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.platform_name}/*"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "oot-build-${var.platform_name}"
  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = {
    Purpose  = "RFC-0055 POC"
    Platform = var.platform_name
  }
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.platform_name}-s3-access"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.permissions.json
}
