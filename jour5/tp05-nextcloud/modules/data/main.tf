# ==============================================================
# modules/data/main.tf
# GRP2 - Akram Ayoub Raphael Pierrick
# TP05 Nextcloud - Rôle 4 : Data Engineer
#
# Ce module crée :
#   - RDS PostgreSQL 16 Multi-AZ chiffré KMS  (rds.tf)
#   - S3 primary storage Nextcloud             (s3.tf)
#   - S3 ALB access logs                       (s3.tf)
#
# Inputs attendus (voir variables.tf) :
#   - vpc_id, private_db_subnet_ids, db_security_group_id
#   - kms_key_arn, db_password_secret_arn
#
# Le KMS, le SG DB et les subnets sont fournis par les autres rôles.
# ==============================================================
