data "aws_iam_policy_document" "app_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "app" {
  name               = "${local.name_prefix}-app"
  assume_role_policy = data.aws_iam_policy_document.app_assume_role.json
  tags               = merge(local.common_tags, { Name = "${local.name_prefix}-app-role" })
}

data "aws_iam_policy_document" "app_s3" {
  statement {
    sid       = "NextcloudS3Objects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:GetObjectVersion", "s3:AbortMultipartUpload"]
    resources = ["${var.s3_primary_bucket_arn}/*"]
  }
  statement {
    sid       = "NextcloudS3Bucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation", "s3:ListBucketMultipartUploads"]
    resources = [var.s3_primary_bucket_arn]
  }
}
resource "aws_iam_role_policy" "app_s3" {
  name   = "${local.name_prefix}-app-s3"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app_s3.json
}

data "aws_iam_policy_document" "app_secrets" {
  statement {
    sid       = "NextcloudSecrets"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [aws_secretsmanager_secret.db_password.arn, aws_secretsmanager_secret.admin_password.arn]
  }
}
resource "aws_iam_role_policy" "app_secrets" {
  name   = "${local.name_prefix}-app-secrets"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app_secrets.json
}

data "aws_iam_policy_document" "app_kms" {
  statement {
    sid       = "NextcloudKmsDecrypt"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = [aws_kms_key.main.arn]
  }
}
resource "aws_iam_role_policy" "app_kms" {
  name   = "${local.name_prefix}-app-kms"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app_kms.json
}

resource "aws_iam_role_policy_attachment" "app_ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_role_policy_attachment" "app_cloudwatch" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "app" {
  name = "${local.name_prefix}-app"
  role = aws_iam_role.app.name
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-app-profile" })
}
