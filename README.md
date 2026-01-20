# 🎮 FCG - Infrastructure Orchestration

Orquestração para executar a plataforma FIAP Cloud Games.

---

## 🐳 Docker Compose (Recomendado)

### Configuração

**1. Cire um arquivo .env a partir do exemplo:**
```bash
cd docker
cp .env.example .env
```

**2. Configure as variáveis obrigatórias:**

Edite o arquivo `.env` com suas credenciais AWS Cognito e GitHub Token.

**Como criar GitHub Token:**
1. Acesse: https://github.com/settings/tokens
2. Clique em **"Generate new token (classic)"**
3. Marque a permissão: **`read:packages`**
4. Copie o token gerado e cole no `.env` em `GITHUB_TOKEN`

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
cd ../..
docker compose -f FCG.Infra.Orchestration/docker/docker-compose.yml build
```

**3. Criar secrets e editar com suas credenciais**
```bash
cp FCG.Api.Users/k8s/secret.yaml.example FCG.Api.Users/k8s/secret.yaml
cp FCG.Api.Catalog/k8s/secret.yaml.example FCG.Api.Catalog/k8s/secret.yaml
```

**4. Deploy**
```bash
cd FCG.Infra.Orchestration/k8s
./deploy-all.sh
```
**5. Verificar e acessar**
```bash
kubectl get pods -w
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

**Grupo 11 - FIAP 2026**
