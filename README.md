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
- AWS CLI configurado com perfil Academy (`aws configure --profile fiapaws`)
- `kubectl` instalado
- Terraform >= 1.5

> **AWS Academy:** as credenciais expiram a cada ~4h. Antes de qualquer comando AWS/Terraform/kubectl, exporte o perfil atualizado:
> ```bash
> export AWS_PROFILE=fiapaws
> ```

### Ordem de deploy

**1. Provisionar infraestrutura base (EKS + ECR)**
```bash
cd terraform
./bootstrap.sh fiapaws   # cria bucket S3 + tabela DynamoDB (apenas na primeira vez)
terraform init
terraform apply -target=module.ecr -target=module.eks
```

**2. Configurar kubectl**
```bash
aws eks update-kubeconfig --name fcg-cluster --region us-east-1
```

**3. Subir imagens no ECR**

Os pipelines CD fazem isso automaticamente a cada push na `main`. Os secrets `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` e `AWS_SESSION_TOKEN` devem estar configurados na organização GitHub.

> Aguarde os pipelines concluírem antes de prosseguir.

**4. Deploy dos microsserviços no EKS**
```bash
cd k8s
./deploy-all.sh
```

> Após o `kubectl apply` dos Services, o AWS Load Balancer Controller cria automaticamente um NLB interno por serviço. Aguarde 2-3 minutos para os NLBs ficarem ativos.

**5. Provisionar Cognito, secrets K8s, API Gateway e Lambdas**
```bash
cd terraform
terraform apply
```

> Este passo cria o Cognito User Pool, gera automaticamente a senha do SQL Server via `random_password`, e cria os secrets K8s (`sqlserver-secret`, `users-api-secret`, `catalog-api-secret`) via provider Kubernetes. Requer que o EKS já exista.

> Se os secrets já existirem no cluster (de um deploy anterior), delete-os antes:
> ```bash
> kubectl delete secret sqlserver-secret users-api-secret catalog-api-secret --ignore-not-found
> ```

**6. Aplicar deployments atualizados**

Após qualquer alteração nos arquivos de deployment das APIs, aplique-os individualmente. Note que `kubectl apply` reseta a imagem para o placeholder do YAML — rode o pipeline CD novamente (ou `kubectl set image`) para restaurar a URI ECR completa:

```bash
kubectl apply -f ../../FCG.Api.Users/k8s/deployment.yaml
kubectl set image deployment/users-api users-api=<account-id>.dkr.ecr.us-east-1.amazonaws.com/fcg-users-api:latest
```

**7. Validar pods**
```bash
kubectl get pods
kubectl get services
```

**8. Teardown após o vídeo**
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

### Arquitetura Cloud (Fase 3)
```
Internet → AWS API Gateway (HTTP API)
            └── VPC Link → NLB interno → EKS
                  ├── FCG.Api.Users      (autenticação via Cognito)
                  ├── FCG.Api.Catalog    (publica OrderPlacedEvent)
                  ├── FCG.Api.Payments   (consome OrderPlacedEvent)
                  └── FCG.Api.Notifications

Lambdas (ECR image):
  ├── FCG.Lambda.Payment      (fcg-payment-processor)
  └── FCG.Lambda.Notification (fcg-notification-sender)

Cognito: User Pool gerenciado pelo Terraform
Secrets K8s: gerenciados pelo Terraform (senha SA gerada via random_password)
```
