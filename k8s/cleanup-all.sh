#!/bin/bash

# Script para remover todos os recursos do Kubernetes

set -e

echo "🗑️  FCG Platform - Kubernetes Cleanup"
echo "======================================"
echo ""

read -p "⚠️  Tem certeza que deseja deletar TODOS os recursos? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

echo "🧹 Removendo recursos..."
echo ""

# Remover microsserviços
echo "📦 Removendo microsserviços..."
kubectl delete -f ../../FCG.Api.Notifications/k8s/ --ignore-not-found=true
kubectl delete -f ../../FCG.Api.Payments/k8s/ --ignore-not-found=true
kubectl delete -f ../../FCG.Api.Catalog/k8s/ --ignore-not-found=true
kubectl delete -f ../../FCG.Api.Users/k8s/ --ignore-not-found=true

echo ""
echo "🏗️  Removendo infraestrutura..."
kubectl delete -f rabbitmq/ --ignore-not-found=true
kubectl delete -f sqlserver/ --ignore-not-found=true

echo ""
echo "⏳ Aguardando terminação dos pods..."
sleep 10

echo ""
echo "======================================"
echo "✅ Cleanup completo!"
echo "======================================"
echo ""
kubectl get all 2>/dev/null || echo "Nenhum recurso encontrado."
echo ""
