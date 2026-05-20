# FCG - Infrastructure Orchestration

**Tech Challenge - Fase 4**  
Orquestração para executar a plataforma FIAP Cloud Games.

---

## 📋 Pré-requisitos

Clone todos os repositórios dentro de um diretório raiz comum:

```bash
mkdir fcg && cd fcg

git clone https://github.com/TC-FIAP-Grupo-11/api.users.git          FCG.Api.Users
git clone https://github.com/TC-FIAP-Grupo-11/api.catalog.git         FCG.Api.Catalog
git clone https://github.com/TC-FIAP-Grupo-11/api.payments.git        FCG.Api.Payments
git clone https://github.com/TC-FIAP-Grupo-11/api.notifications.git   FCG.Api.Notifications
git clone https://github.com/TC-FIAP-Grupo-11/infra.orchestration.git FCG.Infra.Orchestration
```

**Estrutura esperada:**
```
fcg/
├── FCG.Api.Users/
├── FCG.Api.Catalog/
├── FCG.Api.Payments/
├── FCG.Api.Notifications/
└── FCG.Infra.Orchestration/
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
- MongoDB: `mongodb://localhost:27017`
- Redis: `localhost:6379`
- Elasticsearch: `http://localhost:9200`

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
cp api.payments/k8s/secret.yaml.example api.payments/k8s/secret.yaml
cp api.notifications/k8s/secret.yaml.example api.notifications/k8s/secret.yaml
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

## ☁️ Deploy na AWS (Fase 4)

### Pré-requisitos
- AWS CLI configurado com perfil Academy (`aws configure --profile fiapaws`)
- `kubectl` instalado
- Terraform >= 1.5
- Secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` e `AWS_SESSION_TOKEN` configurados na organização GitHub
- `terraform/terraform.tfvars` criado com as variáveis obrigatórias

> **AWS Academy:** as credenciais expiram a cada ~4h. Atualize o perfil `fiapaws` com as credenciais do painel Academy antes de executar qualquer comando.

### Deploy automatizado

O script `terraform/deploy.sh` orquestra todo o processo:

```bash
cd terraform
./deploy.sh fiapaws
```

O script executa automaticamente:
1. Valida credenciais AWS e pré-requisitos
2. Bootstrap (bucket S3 + tabela DynamoDB para estado remoto)
3. **Fase 1** — ECR, EKS, Cognito
4. Configura `kubectl` + ajusta IMDS hop limit nos nodes
5. Pausa para aguardar pipelines CD subirem imagens no ECR (6 repos)
6. Deploy dos microsserviços no EKS (`./deploy-all.sh`)
7. Aguarda NLBs ficarem ativos (~3 min)
8. **Fase 2** — Lambda, ElastiCache, OpenSearch, MongoDB Atlas, K8s Secrets, API Gateway

> O OpenSearch leva ~15 min para ficar disponível após o apply da Fase 2.

**Validar após o deploy:**
```bash
kubectl get pods
kubectl get services
terraform output api_gateway_endpoint
```

**Teardown após o vídeo:**
```bash
cd k8s && ./cleanup-all.sh
cd ../terraform && terraform destroy
```

---

## ⚠️ Limitações do AWS Academy

O ambiente AWS Academy impõe restrições que diferem de uma conta AWS real. Esta seção documenta cada limitação encontrada, seu impacto e a solução adotada.

### 1. Credenciais expiram a cada ~4 horas

**Impacto:** AWS CLI, Terraform e pipelines GitHub Actions param de funcionar com erro `NoCredentialProviders` ou `InvalidClientTokenId`.

**Solução:** Atualizar o perfil `fiapaws` com as novas credenciais do painel Academy e re-exportar:
```bash
export AWS_PROFILE=fiapaws
```
Para os pipelines, atualizar os secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` e `AWS_SESSION_TOKEN` na organização GitHub.

---

### 2. Sem permissão para criar IAM Roles (`iam:CreateRole`)

**Impacto:** Não é possível criar roles IAM via Terraform. Módulos da comunidade (ex: `terraform-aws-modules/eks`) chamam `aws_iam_session_context` internamente e falham com 403.

**Solução:** Usar a `LabRole` pré-existente para todos os recursos (EKS cluster, node group, Lambda). Substituir o módulo comunitário por recursos `aws_eks_cluster` e `aws_eks_node_group` customizados.

---

### 3. Sem EBS CSI Driver (sem StorageClass)

**Impacto:** PersistentVolumeClaims ficam em `Pending` indefinidamente — os pods de SQL Server e RabbitMQ não conseguem ser agendados.

**Solução:** Substituir `persistentVolumeClaim` por `emptyDir: {}` nos deployments. Os dados são perdidos ao reiniciar o pod, o que é aceitável em ambiente de demonstração.

---

### 4. Sem IRSA (IAM Roles for Service Accounts)

**Impacto:** Pods não conseguem assumir roles IAM via OIDC (mecanismo padrão para dar permissões AWS a pods EKS sem credenciais estáticas).

**Solução:** Pods usam o IMDS (Instance Metadata Service) da `LabRole` anexada ao node group. Requer hop limit = 2 nos nodes (ver limitação abaixo).

---

### 5. IMDS hop limit = 1 nos nodes EKS

**Impacto:** Por padrão, os nodes EC2 têm hop limit = 1 para requisições ao IMDS. Pods dentro de containers precisam de 2 saltos (container → node → IMDS), resultando em erro 401 ao tentar usar credenciais via IMDS.

**Solução:** Aumentar o hop limit para 2 nos nodes em execução:
```bash
for id in $(aws ec2 describe-instances \
  --filters "Name=tag:aws:eks:cluster-name,Values=fcg-cluster" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text); do
  aws ec2 modify-instance-metadata-options \
    --instance-id $id \
    --http-put-response-hop-limit 2 \
    --http-tokens optional
done
```
Este comando deve ser executado após provisionar o node group (passo 1 do deploy) e **repetido sempre que a sessão do AWS Academy expirar**, pois os nodes podem ser recriados com hop limit = 1 novamente.

---

### 6. `kubectl apply` reseta a imagem do deployment

**Impacto:** Ao aplicar um arquivo `deployment.yaml` que contém `image: fcg-users-api:latest` (placeholder), a imagem é revertida para o placeholder, causando `ImagePullBackOff`.

**Causa:** Os pipelines CD usam `kubectl set image` para definir a URI completa do ECR, mas essa alteração não é persistida no YAML do repositório.

**Solução:** Após qualquer `kubectl apply` em um deployment de API, redefina a imagem manualmente:
```bash
kubectl set image deployment/<nome> <container>=<account-id>.dkr.ecr.us-east-1.amazonaws.com/<repo>:latest
```

### Arquitetura Cloud (Fase 4)
```
Internet → AWS API Gateway (HTTP API)
            └── VPC Link → NLB interno → EKS
                  ├── FCG.Api.Users      (auth via Cognito)
                  ├── FCG.Api.Catalog    (cache Redis, reviews MongoDB, busca OpenSearch)
                  ├── FCG.Api.Payments   (consome OrderPlacedEvent)
                  └── FCG.Api.Notifications

Serviços gerenciados (Terraform):
  ├── ElastiCache Redis       — cache de listagens do CatalogAPI
  ├── MongoDB Atlas M0        — avaliações de jogos (GameReviews)
  ├── Amazon OpenSearch       — índice de busca fuzzy de jogos
  └── AWS Cognito             — autenticação JWT

Lambdas (ECR image):
  ├── FCG.Lambda.Payment      (fcg-payment-processor)
  └── FCG.Lambda.Notification (fcg-notification-sender)

Secrets K8s: todos gerenciados pelo Terraform (nenhuma credencial em arquivos versionados)
```
