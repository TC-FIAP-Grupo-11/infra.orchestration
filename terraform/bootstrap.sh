#!/bin/bash

# Cria o bucket S3 e tabela DynamoDB para o backend remoto do Terraform.
# Execute UMA VEZ antes do primeiro "terraform init".

set -e

PROFILE="${1:-fiapaws}"
export AWS_PROFILE=$PROFILE

REGION="us-east-1"
BUCKET="fcg-terraform-state"
TABLE="fcg-terraform-locks"

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

echo "==> Criando tabela DynamoDB para lock: $TABLE"
aws dynamodb create-table \
  --table-name $TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION

echo ""
echo "Bootstrap concluido! Agora execute:"
echo "  terraform init"
