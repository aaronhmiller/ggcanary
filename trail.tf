
data "aws_caller_identity" "current" {}


resource "aws_cloudtrail" "ggcanary_trail" { # ggignore-iac: GG_IAC_0027
  name                          = "${var.global_prefix}-trail"
  s3_bucket_name                = aws_s3_bucket.ggcanary_bucket.id
  s3_key_prefix                 = "ux-validation"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }
  # https://github.com/hashicorp/terraform/issues/6388
  depends_on = [aws_s3_bucket_policy.ggcanary_bucket_policy]
}


data "aws_iam_policy_document" "ggcanary_bucket" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = ["arn:aws:s3:::${var.global_prefix}-bucket"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::${var.global_prefix}-bucket/ux-validation/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      values   = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }
  }
}

resource "aws_s3_bucket" "ggcanary_bucket" {
  bucket        = "${var.global_prefix}-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "ggcanary_bucket_policy" {
  bucket = aws_s3_bucket.ggcanary_bucket.id
  policy = data.aws_iam_policy_document.ggcanary_bucket.json
}

resource "aws_s3_bucket_public_access_block" "ggcanary_bucket_public_access" {
  bucket = aws_s3_bucket.ggcanary_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ggcanary_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.ggcanary_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
