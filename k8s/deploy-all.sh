#!/bin/bash

# Script para deploy completo da aplicação FCG no Kubernetes

set -e

echo "🚀 FCG Platform - Kubernetes Deployment"
echo "========================================"
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl não encontrado. Instale kubectl primeiro."
    exit 1
fi

# Verificar cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cluster Kubernetes não acessível."
    exit 1
fi

echo -e "${GREEN}✅ Cluster Kubernetes acessível${NC}"
echo ""

# 1. Deploy da Infraestrutura
echo "📦 Step 1/5: Deploying Infrastructure (SQL Server + RabbitMQ)"
echo "------------------------------------------------------------"
kubectl apply -f sqlserver/
kubectl apply -f rabbitmq/
echo ""
echo "⏳ Aguardando infraestrutura ficar pronta (60s)..."
sleep 60
echo ""

# 2. Deploy Users API
echo "👤 Step 2/5: Deploying Users API"
echo "------------------------------------------------------------"
kubectl apply -f ../../FCG.Api.Users/k8s/
echo ""
sleep 10

# 3. Deploy Catalog API
echo "🎮 Step 3/5: Deploying Catalog API"
echo "------------------------------------------------------------"
kubectl apply -f ../../FCG.Api.Catalog/k8s/
echo ""
sleep 10

# 4. Deploy Payments API
echo "💳 Step 4/5: Deploying Payments API"
echo "------------------------------------------------------------"
kubectl apply -f ../../FCG.Api.Payments/k8s/
echo ""
sleep 10

# 5. Deploy Notifications API
echo "📧 Step 5/5: Deploying Notifications API"
echo "------------------------------------------------------------"
kubectl apply -f ../../FCG.Api.Notifications/k8s/
echo ""

echo "========================================"
echo -e "${GREEN}✅ Deploy completo!${NC}"
echo "========================================"
echo ""
echo "📊 Status dos recursos:"
echo ""
kubectl get pods
echo ""
kubectl get svc
echo ""
echo "🌐 Para acessar os serviços, execute:"
echo ""
echo "  kubectl port-forward service/users-api-service 5001:80"
echo "  kubectl port-forward service/catalog-api-service 5002:80"
echo "  kubectl port-forward service/rabbitmq-service 15672:15672"
echo ""
