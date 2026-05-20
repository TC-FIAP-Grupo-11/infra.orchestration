#!/bin/bash

# Script para deploy completo da aplicação FCG no Kubernetes

set -e

echo "FCG Platform - Kubernetes Deployment"
echo "========================================"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if ! command -v kubectl &> /dev/null; then
    echo "kubectl nao encontrado. Instale kubectl primeiro."
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    echo "Cluster Kubernetes nao acessivel."
    exit 1
fi

echo -e "${GREEN}Cluster Kubernetes acessivel${NC}"
echo ""

# 1. Infraestrutura base
echo "Step 1/5: Deploying Infrastructure (SQL Server + RabbitMQ)"
echo "------------------------------------------------------------"
kubectl apply -f sqlserver/
kubectl apply -f rabbitmq/
echo ""
echo "Aguardando infraestrutura ficar pronta (60s)..."
sleep 60
echo ""

# 2. Users API
echo "Step 2/5: Deploying Users API"
echo "------------------------------------------------------------"
kubectl apply -f ../../FCG.Api.Users/k8s/
echo ""
sleep 10

# 3. Catalog API
echo "Step 3/5: Deploying Catalog API"
echo "------------------------------------------------------------"
kubectl apply -f ../../FCG.Api.Catalog/k8s/
echo ""
sleep 10

# 4. Payments API
echo "Step 4/5: Deploying Payments API"
echo "------------------------------------------------------------"
kubectl apply -f ../../FCG.Api.Payments/k8s/
echo ""
sleep 10

# 5. Notifications API
echo "Step 5/5: Deploying Notifications API"
echo "------------------------------------------------------------"
kubectl apply -f ../../FCG.Api.Notifications/k8s/
echo ""

echo "========================================"
echo -e "${GREEN}Deploy Kubernetes completo!${NC}"
echo "========================================"
echo ""
kubectl get pods
echo ""
kubectl get svc
echo ""
echo -e "${YELLOW}LEMBRETE: executar Terraform manualmente apos os NLBs estarem prontos.${NC}"
echo "  cd ../terraform && terraform apply"
echo ""
