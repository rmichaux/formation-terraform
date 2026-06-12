#!/usr/bin/env bash
set -euo pipefail

USERNAME="etudiant22"
REGION="eu-west-3"
PROJECT="tp-groupe2"
BUCKET="tf-state-${USERNAME}-${PROJECT}"
KMS_ALIAS="alias/tf-state-${USERNAME}-${PROJECT}"

echo "=== 1. Creation KMS CMK pour chiffrer le state ==="
KMS_KEY_ID=$(aws kms list-aliases --region "${REGION}" --query "Aliases[?AliasName=='${KMS_ALIAS}'].TargetKeyId" --output text)

if [ -z "${KMS_KEY_ID}" ]; then
  KMS_KEY_ID=$(aws kms create-key --region "${REGION}" --description "CMK state Terraform ${PROJECT}" --key-usage ENCRYPT_DECRYPT --key-spec SYMMETRIC_DEFAULT --query 'KeyMetadata.KeyId' --output text)
  aws kms enable-key-rotation --region "${REGION}" --key-id "${KMS_KEY_ID}"
  aws kms create-alias --region "${REGION}" --alias-name "${KMS_ALIAS}" --target-key-id "${KMS_KEY_ID}"
else
  echo "CMK ${KMS_ALIAS} existe deja."
fi

KMS_KEY_ARN=$(aws kms describe-key --region "${REGION}" --key-id "${KMS_KEY_ID}" --query 'KeyMetadata.Arn' --output text)
echo "KMS CMK ARN : ${KMS_KEY_ARN}"

echo "=== 2. Creation bucket S3 state ==="
if aws s3api head-bucket --bucket "${BUCKET}" 2>/dev/null; then
  echo "Bucket ${BUCKET} existe deja."
else
  aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}" --create-bucket-configuration "LocationConstraint=${REGION}"
fi

aws s3api put-bucket-versioning --bucket "${BUCKET}" --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption --bucket "${BUCKET}" --server-side-encryption-configuration "{
    \"Rules\": [{
      \"ApplyServerSideEncryptionByDefault\": {
        \"SSEAlgorithm\": \"aws:kms\",
        \"KMSMasterKeyID\": \"${KMS_KEY_ARN}\"
      },
      \"BucketKeyEnabled\": true
    }]
  }"

aws s3api put-public-access-block --bucket "${BUCKET}" --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

aws s3api put-bucket-policy --bucket "${BUCKET}" --policy "$(cat <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyInsecureTransport",
    "Effect": "Deny",
    "Principal": "*",
    "Action": "s3:*",
    "Resource": ["arn:aws:s3:::${BUCKET}", "arn:aws:s3:::${BUCKET}/*"],
    "Condition": { "Bool": { "aws:SecureTransport": "false" } }
  }]
}
POLICY
)"

echo "Bootstrap OK. Bucket : ${BUCKET} | KMS : ${KMS_ALIAS}"
