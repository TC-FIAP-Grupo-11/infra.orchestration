# 🎮 FCG - FIAP Cloud Games - Kubernetes Deployment

Guia completo para deploy da plataforma FCG em Kubernetes.

## 📋 Requisitos

- **Kubernetes local**: Minikube, Kind ou Docker Desktop com Kubernetes habilitado
- **kubectl** instalado e configurado
- **Docker** para build das imagens

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                       │
│                                                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐           │
│  │  UsersAPI  │  │ CatalogAPI │  │ PaymentsAPI│           │
│  │  (Pod x2)  │  │  (Pod x2)  │  │  (Pod x2)  │           │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘           │
│        │                │                │                   │
│  ┌─────▼────────────────▼────────────────▼─────┐           │
│  │          NotificationsAPI (Pod x2)           │           │
│  └──────────────────┬───────────────────────────┘           │
│                     │                                        │
│  ┌─────────────────▼──────────────────────┐                │
│  │         RabbitMQ (Message Broker)       │                │
│  └─────────────────┬──────────────────────┘                │
│                     │                                        │
│  ┌─────────────────▼──────────────────────┐                │
│  │         SQL Server (Database)           │                │
│  └─────────────────────────────────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Deploy Rápido

### 1. Preparar o Cluster

**Minikube:**
```bash
minikube start --driver=docker --memory=8192 --cpus=4
eval $(minikube docker-env)
```

**Kind:**
```bash
kind create cluster --name fcg-cluster
```

**Docker Desktop:**
```bash
# Habilite Kubernetes nas configurações do Docker Desktop
```

### 2. Build das Imagens Docker

```bash
# Configurar variáveis de ambiente
export GITHUB_USERNAME=seu-usuario
export GITHUB_TOKEN=seu-token

# Build de todas as imagens
docker compose build
```

**Para Minikube/Kind, carregar imagens no cluster:**

```bash
# Minikube
minikube image load fcg-users-api:latest
minikube image load fcg-catalog-api:latest
minikube image load fcg-payments-api:latest
minikube image load fcg-notifications-api:latest

# OU Kind
kind load docker-image fcg-users-api:latest --name fcg-cluster
kind load docker-image fcg-catalog-api:latest --name fcg-cluster
kind load docker-image fcg-payments-api:latest --name fcg-cluster
kind load docker-image fcg-notifications-api:latest --name fcg-cluster
```

### 3. Configurar Secrets

**⚠️ IMPORTANTE**: Edite os secrets com suas credenciais AWS/Cognito:

```bash
# Editar secrets do UsersAPI (dentro do repositório FCG.Api.Users)
nano FCG.Api.Users/k8s/secret.yaml

# Editar secrets do CatalogAPI (dentro do repositório FCG.Api.Catalog)
nano FCG.Api.Catalog/k8s/secret.yaml
```

### 4. Deploy da Infraestrutura

```bash
# Deploy SQL Server
kubectl apply -f k8s/sqlserver-secret.yaml
kubectl apply -f k8s/sqlserver-pvc.yaml
kubectl apply -f k8s/sqlserver-deployment.yaml
kubectl apply -f k8s/sqlserver-service.yaml

# Deploy RabbitMQ
kubectl apply -f k8s/rabbitmq-configmap.yaml
kubectl apply -f k8s/rabbitmq-pvc.yaml
kubectl apply -f k8s/rabbitmq-deployment.yaml
kubectl apply -f k8s/rabbitmq-service.yaml

# Aguardar infraestrutura ficar pronta
kubectl get pods -w
```

### 5. Deploy dos Microsserviços

```bash
# Users API
kubectl apply -f FCG.Api.Users/k8s/

# Catalog API
kubectl apply -f FCG.Api.Catalog/k8s/

# Payments API
kubectl apply -f FCG.Api.Payments/k8s/

# Notifications API
kubectl apply -f FCG.Api.Notifications/k8s/
```

### 6. Verificar Deploy

```bash
# Ver todos os pods
kubectl get pods

# Ver todos os services
kubectl get svc

# Ver logs de um serviço
kubectl logs -l app=users-api
```

## 🌐 Acessar os Serviços

### Port-Forward para acesso local

```bash
# Users API (Swagger)
kubectl port-forward service/users-api-service 5001:80

# Catalog API (Swagger)
kubectl port-forward service/catalog-api-service 5002:80

# RabbitMQ Management
kubectl port-forward service/rabbitmq-service 15672:15672
```

### URLs dos Serviços

- **Users API Swagger**: http://localhost:5001/swagger
- **Catalog API Swagger**: http://localhost:5002/swagger
- **RabbitMQ Management**: http://localhost:15672 (guest/guest)

## 🧪 Testar os Fluxos

### Fluxo de Cadastro de Usuário

```bash
# 1. Cadastrar usuário
curl -X POST http://localhost:5001/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste@example.com",
    "password": "Senha@123",
    "name": "Usuario Teste"
  }'

# 2. Confirmar cadastro (código recebido por email - simulado)
curl -X POST http://localhost:5001/api/auth/confirm-signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste@example.com",
    "code": "123456"
  }'

# 3. Verificar logs do NotificationsAPI
kubectl logs -l app=notifications-api | grep "UserCreatedEvent"
```

### Fluxo de Compra de Jogo

```bash
# 1. Login
TOKEN=$(curl -s -X POST http://localhost:5001/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste@example.com",
    "password": "Senha@123"
  }' | jq -r '.token')

# 2. Listar jogos disponíveis
curl http://localhost:5002/api/games \
  -H "Authorization: Bearer $TOKEN"

# 3. Comprar um jogo
curl -X POST http://localhost:5002/api/games/purchase \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "gameId": "uuid-do-jogo"
  }'

# 4. Verificar logs dos eventos
kubectl logs -l app=payments-api | grep "OrderPlacedEvent"
kubectl logs -l app=catalog-api | grep "PaymentProcessedEvent"
kubectl logs -l app=notifications-api | grep "PaymentProcessedEvent"
```

## 📊 Monitoramento

### Status dos Recursos

```bash
# Pods
kubectl get pods -o wide

# Services
kubectl get svc

# ConfigMaps
kubectl get configmaps

# Secrets
kubectl get secrets

# PVCs
kubectl get pvc

# Deployments
kubectl get deployments
```

### Logs e Troubleshooting

```bash
# Logs de um pod específico
kubectl logs <pod-name>

# Logs em tempo real
kubectl logs -f <pod-name>

# Logs de todos os pods de um deployment
kubectl logs -l app=users-api --all-containers

# Descrever um pod (para debug)
kubectl describe pod <pod-name>

# Eventos do cluster
kubectl get events --sort-by=.metadata.creationTimestamp

# Entrar em um pod
kubectl exec -it <pod-name> -- /bin/bash
```

## 🔧 Comandos Úteis

### Reiniciar um Deployment

```bash
kubectl rollout restart deployment users-api
kubectl rollout restart deployment catalog-api
kubectl rollout restart deployment payments-api
kubectl rollout restart deployment notifications-api
```

### Escalar Replicas

```bash
kubectl scale deployment users-api --replicas=3
```

### Atualizar Imagem

```bash
# Rebuild da imagem
docker compose build users-api

# Reload no cluster (Minikube)
minikube image load fcg-users-api:latest

# Reiniciar deployment
kubectl rollout restart deployment users-api
```

## 🗑️ Limpeza

### Remover todos os recursos

```bash
# Remover microsserviços
kubectl delete -f FCG.Api.Notifications/k8s/
kubectl delete -f FCG.Api.Payments/k8s/
kubectl delete -f FCG.Api.Catalog/k8s/
kubectl delete -f FCG.Api.Users/k8s/

# Remover infraestrutura
kubectl delete -f k8s/rabbitmq-service.yaml
kubectl delete -f k8s/rabbitmq-deployment.yaml
kubectl delete -f k8s/rabbitmq-pvc.yaml
kubectl delete -f k8s/rabbitmq-configmap.yaml

kubectl delete -f k8s/sqlserver-service.yaml
kubectl delete -f k8s/sqlserver-deployment.yaml
kubectl delete -f k8s/sqlserver-pvc.yaml
kubectl delete -f k8s/sqlserver-secret.yaml

# Verificar
kubectl get all
```

### Deletar cluster

```bash
# Minikube
minikube delete

# Kind
kind delete cluster --name fcg-cluster
```

## 📁 Estrutura dos Manifestos

```
├── k8s/ (Repositório de Orquestração)
│   ├── sqlserver-secret.yaml
│   ├── sqlserver-pvc.yaml
│   ├── sqlserver-deployment.yaml
│   ├── sqlserver-service.yaml
│   ├── rabbitmq-configmap.yaml
│   ├── rabbitmq-pvc.yaml
│   ├── rabbitmq-deployment.yaml
│   └── rabbitmq-service.yaml
│
├── FCG.Api.Users/k8s/
│   ├── secret.yaml
│   ├── configmap.yaml
│   ├── deployment.yaml
│   └── service.yaml
│
├── FCG.Api.Catalog/k8s/
│   ├── secret.yaml
│   ├── configmap.yaml
│   ├── deployment.yaml
│   └── service.yaml
│
├── FCG.Api.Payments/k8s/
│   ├── configmap.yaml
│   ├── deployment.yaml
│   └── service.yaml
│
└── FCG.Api.Notifications/k8s/
    ├── configmap.yaml
    ├── deployment.yaml
    └── service.yaml
```

## 🎓 Para o Tech Challenge

### Comandos para Demonstração no Vídeo

```bash
# 1. Mostrar estrutura
tree -L 2

# 2. Deploy completo
kubectl apply -f k8s/
kubectl apply -f FCG.Api.Users/k8s/
kubectl apply -f FCG.Api.Catalog/k8s/
kubectl apply -f FCG.Api.Payments/k8s/
kubectl apply -f FCG.Api.Notifications/k8s/

# 3. Verificar pods
kubectl get pods -w

# 4. Verificar services
kubectl get svc

# 5. Port-forward
kubectl port-forward service/users-api-service 5001:80 &
kubectl port-forward service/catalog-api-service 5002:80 &

# 6. Testar fluxos (ver seção acima)

# 7. Mostrar logs dos eventos
kubectl logs -l app=notifications-api --tail=20
```

## ⚠️ Notas Importantes

1. **Secrets**: Nunca commite secrets reais no Git. Os valores nos arquivos são placeholders.

2. **ImagePullPolicy**: Configurado como `Never` para uso local. Em produção, use um registry e `Always`.

3. **Resources**: Limites de recursos estão configurados para ambiente local. Ajuste para produção conforme necessário.

4. **LoadBalancer vs ClusterIP**: 
   - Users API e Catalog API: LoadBalancer (acesso externo)
   - Payments e Notifications: ClusterIP (interno apenas)

5. **Health Checks**: Todos os deployments incluem liveness e readiness probes.

## 🔗 Links dos Repositórios

- **Users API**: https://github.com/TC-FIAP-Grupo-11/api.users
- **Catalog API**: https://github.com/TC-FIAP-Grupo-11/api.catalog
- **Payments API**: https://github.com/TC-FIAP-Grupo-11/api.payments
- **Notifications API**: https://github.com/TC-FIAP-Grupo-11/api.notifications
- **Shared Library**: https://github.com/TC-FIAP-Grupo-11/FCG.Lib.Shared

---

**Desenvolvido por:** TC-FIAP-Grupo-11  
**Tech Challenge - Fase 2**  
**Janeiro 2026**
