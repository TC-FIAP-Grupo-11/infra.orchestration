#!/bin/bash

# Cria o bucket S3 e tabela DynamoDB para o backend remoto do Terraform.
# Idempotente — seguro de executar múltiplas vezes.

set -e

PROFILE="${1:-fiapaws}"
export AWS_PROFILE=$PROFILE

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="fcg-terraform-state-${ACCOUNT_ID}"
TABLE="fcg-terraform-locks"

echo "  Bucket: $BUCKET"

# Bucket S3
if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "==> Bucket S3 já existe: $BUCKET"
else
  echo "==> Criando bucket S3: $BUCKET"
  aws s3 mb s3://$BUCKET --region $REGION

  echo "==> Habilitando versionamento no bucket"
  aws s3api put-bucket-versioning \
    --bucket $BUCKET \
    --versioning-configuration Status=Enabled

  echo "==> Habilitando criptografia no bucket"
  aws s3api put-bucket-encryption \
    --bucket $BUCKET \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }]
    }'
fi

# Tabela DynamoDB
if aws dynamodb describe-table --table-name "$TABLE" --region $REGION 2>/dev/null; then
  echo "==> Tabela DynamoDB já existe: $TABLE"
else
  echo "==> Criando tabela DynamoDB para lock: $TABLE"
  aws dynamodb create-table \
    --table-name $TABLE \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $REGION
fi

echo ""
echo "Bootstrap concluido! Agora execute:"
echo "  terraform init"
