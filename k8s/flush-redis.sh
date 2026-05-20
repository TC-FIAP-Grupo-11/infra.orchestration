#!/bin/bash

REDIS_HOST=$(kubectl get secret catalog-api-secret -o jsonpath='{.data.REDIS_CONNECTION_STRING}' | base64 -d | cut -d: -f1)

echo "Redis: $REDIS_HOST"
echo "Limpando cache..."

kubectl run redis-flush --image=redis:7-alpine --rm -it --restart=Never -- \
  redis-cli -h $REDIS_HOST FLUSHALL

echo "Cache limpo."
