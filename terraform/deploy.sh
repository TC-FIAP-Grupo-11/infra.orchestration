#!/bin/bash
# Deploy completo da infraestrutura FCG — primeira subida ou redeploy.
# Uso: ./deploy.sh [perfil-aws]  (padrão: fiapaws)

set -e

PROFILE="${1:-fiapaws}"
REGION="us-east-1"
CLUSTER="fcg-cluster"

export AWS_PROFILE=$PROFILE

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

step()  { echo -e "\n${GREEN}==>${NC} $1"; }
warn()  { echo -e "${YELLOW}AVISO:${NC} $1"; }
error() { echo -e "${RED}ERRO:${NC} $1"; }
pause() { read -rp "  $1 — pressione Enter para continuar..."; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ---------------------------------------------------------------------------
# Credenciais AWS
# ---------------------------------------------------------------------------
step "Verificando credenciais AWS (perfil: $PROFILE)"
warn "As credenciais do AWS Academy expiram a cada ~4h."
warn "Certifique-se de ter atualizado o perfil '$PROFILE' com as credenciais atuais do painel Academy."
echo ""

if ! aws sts get-caller-identity --output text > /dev/null 2>&1; then
  error "Credenciais inválidas ou expiradas para o perfil '$PROFILE'."
  echo  "  Atualize ~/.aws/credentials com as credenciais do painel Academy e execute novamente."
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="fcg-terraform-state-${ACCOUNT_ID}"
echo "  Conta AWS: $ACCOUNT_ID — OK"

# ---------------------------------------------------------------------------
# Pré-requisitos
# ---------------------------------------------------------------------------
step "Verificando pré-requisitos"
command -v kubectl   >/dev/null || { error "kubectl não encontrado"; exit 1; }
command -v terraform >/dev/null || { error "Terraform não encontrado"; exit 1; }

if [ ! -f terraform.tfvars ]; then
  error "terraform.tfvars não encontrado — crie o arquivo com as variáveis obrigatórias."
  exit 1
fi
echo "OK"

# ---------------------------------------------------------------------------
# Bootstrap + init
# ---------------------------------------------------------------------------
step "Bootstrap (bucket S3 + tabela DynamoDB para estado remoto)"
./bootstrap.sh "$PROFILE"

step "terraform init"
rm -f .terraform.lock.hcl
terraform init -reconfigure -backend-config="bucket=${BUCKET}"

# ---------------------------------------------------------------------------
# Fase 1 — ECR, EKS, Cognito (sem provider kubernetes, sem imagens necessárias)
# ---------------------------------------------------------------------------
step "Fase 1/2 — ECR, EKS, Cognito"
warn "Terraform exibirá o plano. Revise e confirme com 'yes'."
terraform apply \
  -target=module.ecr \
  -target=module.eks \
  -target=module.cognito

# ---------------------------------------------------------------------------
# Configurar kubectl
# ---------------------------------------------------------------------------
step "Configurando kubectl"
aws eks update-kubeconfig --name "$CLUSTER" --region "$REGION"

echo ""
echo "  Contexto ativo:"
kubectl config current-context
echo ""
echo "  Nodes do cluster:"
kubectl get nodes
echo ""
pause "Confirme que o kubectl está apontando para o cluster correto"

# ---------------------------------------------------------------------------
# Ajuste de IMDS hop limit (limitação do AWS Academy)
# Pods precisam de 2 saltos para acessar credenciais via IMDS
# ---------------------------------------------------------------------------
step "Ajustando IMDS hop limit nos nodes (AWS Academy)"
for id in $(aws ec2 describe-instances \
  --filters "Name=tag:aws:eks:cluster-name,Values=$CLUSTER" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text); do
  aws ec2 modify-instance-metadata-options \
    --instance-id "$id" \
    --http-put-response-hop-limit 2 \
    --http-tokens optional \
    --output text > /dev/null
  echo "  node $id ajustado"
done

echo ""
pause "Confirme que todos os nodes foram ajustados corretamente"

# ---------------------------------------------------------------------------
# Pipelines CD — imagens no ECR
# ---------------------------------------------------------------------------
echo ""
warn "As imagens Docker precisam estar no ECR antes de continuar."
warn "Faça push na branch 'main' de TODOS os repositórios:"
echo "    - api.users"
echo "    - api.catalog"
echo "    - api.payments"
echo "    - api.notifications"
echo "    - lambda.payment"
echo "    - lambda.notification"
warn "Aguarde todos os pipelines CD concluírem com sucesso."
pause "Quando todos os pipelines tiverem concluído"

# ---------------------------------------------------------------------------
# Deploy dos microsserviços no EKS
# ---------------------------------------------------------------------------
step "Deploy dos microsserviços no EKS"
cd "$SCRIPT_DIR/../k8s" && ./deploy-all.sh
cd "$SCRIPT_DIR"

# ---------------------------------------------------------------------------
# Aguardar NLBs ficarem ativos
# ---------------------------------------------------------------------------
step "Aguardando NLBs ficarem ativos (~3 min)"
for i in $(seq 1 18); do
  printf "."
  sleep 10
done
echo " pronto"

# ---------------------------------------------------------------------------
# Fase 2 — Lambda, ElastiCache, OpenSearch, MongoDB Atlas, K8s Secrets, API Gateway
# ---------------------------------------------------------------------------
step "Fase 2/2 — Lambda, ElastiCache, OpenSearch, MongoDB Atlas, K8s Secrets, API Gateway"
warn "OpenSearch leva ~15 min para ficar disponível após o apply."
warn "Terraform exibirá o plano. Revise e confirme com 'yes'."
terraform apply

# ---------------------------------------------------------------------------
# Resultado
# ---------------------------------------------------------------------------
step "Infraestrutura provisionada com sucesso!"
echo ""
echo "API Gateway URL:"
terraform output api_gateway_endpoint
echo ""
warn "Lembre de redirecionar os deployments para as imagens ECR corretas:"
echo "  kubectl set image deployment/<nome> <container>=<account>.dkr.ecr.$REGION.amazonaws.com/<repo>:latest"
