# -----------------------------------------------------------------------------
# Platform 1 role - federated from afrittoli/sandbox
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "platform1_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/sandbox:*"]
    }
  }
}

data "aws_iam_policy_document" "platform1_permissions" {
  statement {
    sid = "AllowPrefixedObjectAccess"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.artifacts.arn}/platform1/*",
    ]
  }

  statement {
    sid = "AllowListBucketWithPrefix"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.artifacts.arn,
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["platform1/*"]
    }
  }
}

resource "aws_iam_role" "platform1" {
  name               = "oot-build-platform1"
  assume_role_policy = data.aws_iam_policy_document.platform1_trust.json

  tags = {
    Purpose  = "RFC-0055 POC"
    Platform = "platform1"
  }
}

resource "aws_iam_role_policy" "platform1" {
  name   = "platform1-s3-access"
  role   = aws_iam_role.platform1.id
  policy = data.aws_iam_policy_document.platform1_permissions.json
}

# -----------------------------------------------------------------------------
# Platform 2 role - federated from afrittoli/sandbox-2
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "platform2_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/sandbox-2:*"]
    }
  }
}

data "aws_iam_policy_document" "platform2_permissions" {
  statement {
    sid = "AllowPrefixedObjectAccess"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.artifacts.arn}/platform2/*",
    ]
  }

  statement {
    sid = "AllowListBucketWithPrefix"

    actions = [
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.artifacts.arn,
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["platform2/*"]
    }
  }
}

resource "aws_iam_role" "platform2" {
  name               = "oot-build-platform2"
  assume_role_policy = data.aws_iam_policy_document.platform2_trust.json

  tags = {
    Purpose  = "RFC-0055 POC"
    Platform = "platform2"
  }
}

resource "aws_iam_role_policy" "platform2" {
  name   = "platform2-s3-access"
  role   = aws_iam_role.platform2.id
  policy = data.aws_iam_policy_document.platform2_permissions.json
}
