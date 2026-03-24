# 🎮 FCG - Infrastructure Orchestration

Orquestração para executar a plataforma FIAP Cloud Games.

---

## 📋 Pré-requisitos

Clone todos os repositórios no mesmo nível:

```bash
mkdir fcg && cd fcg

# Clone os repositórios
git clone https://github.com/TC-FIAP-Grupo-11/api.users.git
git clone https://github.com/TC-FIAP-Grupo-11/api.catalog.git
git clone https://github.com/TC-FIAP-Grupo-11/api.payments.git
git clone https://github.com/TC-FIAP-Grupo-11/api.notifications.git
git clone https://github.com/TC-FIAP-Grupo-11/infra.orchestration.git
```

**Estrutura esperada:**
```
fcg/
├── api.users/
├── api.catalog/
├── api.payments/
├── api.notifications/
└── infra.orchestration/
```

---

## 🐳 Docker Compose

### Configuração

**1. Crie um arquivo .env a partir do exemplo:**
```bash
cd infra.orchestration/docker
cp .env.example .env
```

**2. Configure as variáveis obrigatórias:**

Edite o arquivo `.env` com suas credenciais AWS Cognito.

**3. Execute:**
```bash
docker compose up -d --build
```

**Acessar:**
- Users API: `http://localhost:5001/swagger` | `/health`
- Catalog API: `http://localhost:5002/swagger` | `/health`
- RabbitMQ: `http://localhost:15672` (guest/guest)

**Comandos:**
```bash
docker compose logs -f    # Ver logs
docker compose down       # Parar
```

---

## ☸️ Kubernetes

**1. Garanta que seu cluster Kubernetes está rodando**
```bash
kubectl cluster-info
```

**2. Build das imagens**
```bash
cd fcg
docker compose -f infra.orchestration/docker/docker-compose.yml build
```

**3. Criar secrets e editar com suas credenciais**
```bash
cp api.users/k8s/secret.yaml.example api.users/k8s/secret.yaml
cp api.catalog/k8s/secret.yaml.example api.catalog/k8s/secret.yaml
# Edite os arquivos com suas credenciais
```

**4. Deploy**
```bash
cd infra.orchestration/k8s
./deploy-all.sh
```

**5. Verificar e acessar**
```bash
kubectl get pods
kubectl port-forward service/users-api-service 5001:80
kubectl port-forward service/catalog-api-service 5002:80
```

Acesse: `http://localhost:5001/health` e `/swagger`

**Comandos úteis:**
```bash
kubectl get pods              # Ver status
kubectl logs -l app=users-api # Ver logs
./cleanup-all.sh              # Limpar tudo
```

---

## ☁️ Deploy na AWS (Fase 3)

### Pré-requisitos
- AWS CLI configurado (`aws configure`)
- `kubectl` com kubeconfig apontando para o cluster EKS
- Terraform >= 1.5

### Ordem de deploy

**1. Provisionar infraestrutura base (EKS + ECR)**
```bash
cd terraform
terraform init
terraform apply -target=module.ecr -target=module.eks
```

**2. Subir imagens no ECR**

Os pipelines CD fazem isso automaticamente a cada push na `main` de cada repositório. Basta garantir que os secrets `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` estejam configurados em cada repo GitHub.

**3. Deploy dos microsserviços no EKS**
```bash
cd k8s
./deploy-all.sh
```

> Após o `kubectl apply` dos Services, o AWS Load Balancer Controller cria automaticamente um NLB interno por serviço e os taggeia com `kubernetes.io/service-name`. Aguarde 2-3 minutos para os NLBs ficarem ativos.

**4. Provisionar API Gateway e Lambdas**
```bash
cd terraform
terraform apply
```

> O módulo `apigateway` usa `data "aws_lb"` para descobrir os ARNs dos NLBs automaticamente pelas tags — não é necessário informar ARNs manualmente.

**5. Validar pods**
```bash
kubectl get pods
kubectl get services
```

**6. Teardown após o vídeo**
```bash
cd k8s && ./cleanup-all.sh
cd ../terraform && terraform destroy
```

### Arquitetura Cloud (Fase 3)
```
Internet → AWS API Gateway (HTTP API)
            └── JWT Authorizer (Cognito)
            └── VPC Link → NLB interno → EKS
                  ├── FCG.Api.Users      (invoca Lambda.Notification)
                  ├── FCG.Api.Catalog    (publica OrderPlacedEvent)
                  ├── FCG.Api.Payments   (consome OrderPlacedEvent, invoca Lambda.Notification)
                  └── FCG.Api.Notifications (deprecado)

Lambdas (ECR image):
  ├── FCG.Lambda.Payment      (fcg-payment-processor)
  └── FCG.Lambda.Notification (fcg-notification-sender)
```

---

**Grupo 11 - FIAP 2026**
