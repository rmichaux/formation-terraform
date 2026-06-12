resource "aws_kms_key" "main" {
  description             = "CMK principale ${local.name_prefix}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootAccountAccess"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowAppRoleUsage"
        Effect    = "Allow"
        Principal = {
          AWS = aws_iam_role.app.arn
        }
        Action    = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ]
        Resource  = "*"
      }
    ]
  })
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-main-kms" })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.name_prefix}-main"
  target_key_id = aws_kms_key.main.key_id
}
