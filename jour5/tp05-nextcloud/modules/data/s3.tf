# ==============================================================
# modules/data/s3.tf
# GRP2 - Akram Ayoub Raphael Pierrick
# S3 primary storage Nextcloud + S3 ALB access logs
# Nommage : grp2-<project>-<env>-* pour éviter les collisions
# ==============================================================

# ---------------------------------------------------------------
# Data source : ARN du compte service ELB (pour policy logs ALB)
# ---------------------------------------------------------------
data "aws_elb_service_account" "main" {}

# ---------------------------------------------------------------
# LOCAL : locals pour les noms de buckets (DRY)
# ---------------------------------------------------------------
locals {
  bucket_primary_name = lower("grp2-${var.project_name}-${var.environment}-nextcloud-primary")
  bucket_logs_name    = lower("grp2-${var.project_name}-${var.environment}-alb-logs")

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Team        = "GRP2-Akram-Ayoub-Raphael-Pierrick"
    ManagedBy   = "terraform"
    Role        = "data"
  }
}

# ==============================================================
# BUCKET PRIMARY — stockage Nextcloud (fichiers avocats)
# ==============================================================

resource "aws_s3_bucket" "primary" {
  bucket = local.bucket_primary_name

  tags = merge(local.common_tags, {
    Name    = local.bucket_primary_name
    Purpose = "nextcloud-primary-storage"
  })
}

# Versioning activé (restauration fichier écrasé par secrétaire)
resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Chiffrement SSE-KMS avec la CMK du Rôle 5
resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true # réduit les appels KMS (coût)
  }
}

# Block Public Access 4/4
resource "aws_s3_bucket_public_access_block" "primary" {
  bucket = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy : deny insecure transport (HTTP interdit)
data "aws_iam_policy_document" "primary_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.primary.arn,
      "${aws_s3_bucket.primary.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "primary" {
  bucket = aws_s3_bucket.primary.id
  policy = data.aws_iam_policy_document.primary_policy.json

  depends_on = [aws_s3_bucket_public_access_block.primary]
}

# ==============================================================
# BUCKET LOGS — ALB access logs (consommé par Rôle 3)
# ==============================================================

resource "aws_s3_bucket" "logs" {
  bucket = local.bucket_logs_name

  tags = merge(local.common_tags, {
    Name    = local.bucket_logs_name
    Purpose = "alb-access-logs"
  })
}

# Chiffrement SSE-KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

# Block Public Access 4/4
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy : autorise le service account ELB à écrire + deny HTTP
data "aws_iam_policy_document" "logs_policy" {
  # ALB doit pouvoir écrire ses logs (service account AWS canonique eu-west-3)
  statement {
    sid    = "AllowALBServiceAccountWrite"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/alb-logs/*"]
  }

  # Deny insecure transport
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.logs.arn,
      "${aws_s3_bucket.logs.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs_policy.json

  depends_on = [aws_s3_bucket_public_access_block.logs]
}

# Lifecycle : transition Glacier J+30, expiration J+90
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "grp2-alb-logs-lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER_IR" # Glacier Instant Retrieval
    }

    expiration {
      days = 90
    }

    # S'applique à tous les objets du bucket
    filter {}
  }
}
