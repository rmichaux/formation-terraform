#!/usr/bin/env bash
# bootstrap/create-state-bucket.sh
# Crée le bucket S3 qui stocke les states Terraform du TP04.
# A executer UNE SEULE FOIS avant d utiliser les backends S3 dans envs/*.

set -euo pipefail

# === A ADAPTER ===
USERNAME="etudiant20"   # remplacez par votre identifiant unique (sans espaces, sans accents)
REGION="eu-west-3"

BUCKET="tf-state-${USERNAME}-formation"

echo "Creation du bucket : ${BUCKET} en ${REGION}"

# 1. Creer le bucket (eu-west-3 requiert LocationConstraint)
aws s3api create-bucket \
  --bucket "${BUCKET}" \
  --region "${REGION}" \
  --create-bucket-configuration "LocationConstraint=${REGION}"

# 2. Activer le versioning (protection contre corruption du state)
aws s3api put-bucket-versioning \
  --bucket "${BUCKET}" \
  --versioning-configuration Status=Enabled

# 3. Chiffrement SSE-S3 (AES256 gere par AWS)
aws s3api put-bucket-encryption \
  --bucket "${BUCKET}" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# 4. Block Public Access (4 options a true)
aws s3api put-public-access-block \
  --bucket "${BUCKET}" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# 5. Bucket policy : refuser toute requete non-HTTPS
aws s3api put-bucket-policy \
  --bucket "${BUCKET}" \
  --policy "$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyInsecureTransport",
    "Effect": "Deny",
    "Principal": "*",
    "Action": "s3:*",
    "Resource": [
      "arn:aws:s3:::${BUCKET}",
      "arn:aws:s3:::${BUCKET}/*"
    ],
    "Condition": {
      "Bool": { "aws:SecureTransport": "false" }
    }
  }]
}
EOF
)"

echo ""
echo "Bucket ${BUCKET} cree avec succes."
echo "Noter le nom, il servira dans backend.tf de envs/dev et envs/staging."
