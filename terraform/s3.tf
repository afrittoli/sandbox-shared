resource "aws_s3_bucket" "artifacts" {
  bucket = var.bucket_name

  tags = {
    Purpose = "RFC-0055 POC - Out-of-tree platform build artifacts"
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
