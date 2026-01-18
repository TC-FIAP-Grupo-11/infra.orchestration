# FCG - FIAP Cloud Games
## Microservices Architecture with Messaging

### 🏗️ Arquitetura

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│  UsersAPI   │────▶│  CatalogAPI  │────▶│ PaymentsAPI  │────▶│ NotificationsAPI │
│   :5001     │     │    :5002     │     │    :5003     │     │      :5004       │
└─────────────┘     └──────────────┘     └──────────────┘     └──────────────────┘
       │                    │                    │                       │
       │                    │                    │                       │
       └────────────────────┴────────────────────┴───────────────────────┘
                                      │
                              ┌───────▼────────┐
                              │   RabbitMQ     │
                              │    :5672       │
                              │  UI: :15672    │
                              └────────────────┘
                                      │
                              ┌───────▼────────┐
                              │  SQL Server    │
                              │    :1433       │
                              └────────────────┘
```

### 🚀 Como Executar

#### **Pré-requisitos**
- Docker & Docker Compose
- .NET 8 SDK (para desenvolvimento local)

#### **1. Configurar Variáveis de Ambiente**

```bash
cp .env.example .env
# Edite o arquivo .env com suas credenciais AWS/Cognito
```

#### **2. Subir Toda a Infraestrutura**

```bash
# Build e start de todos os serviços
docker-compose up -d --build

# Ver logs de todos os serviços
docker-compose logs -f

# Ver logs de um serviço específico
docker-compose logs -f users-api
```

#### **3. Verificar Health**

```bash
# SQL Server
docker exec fcg-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P YourStrong@Passw0rd -Q "SELECT 1"

# RabbitMQ
curl http://localhost:15672
# Login: guest / guest

# APIs
curl http://localhost:5001/swagger # Users API
curl http://localhost:5002/swagger # Catalog API
curl http://localhost:5003/swagger # Payments API
curl http://localhost:5004/swagger # Notifications API
```

### 📋 Serviços

| Serviço | Porta | Descrição |
|---------|-------|-----------|
| **SQL Server** | 1433 | Banco de dados principal |
| **RabbitMQ** | 5672 | Message broker |
| **RabbitMQ UI** | 15672 | Interface web (guest/guest) |
| **Users API** | 5001 | Gerenciamento de usuários |
| **Catalog API** | 5002 | Catálogo de jogos |
| **Payments API** | 5003 | Processamento de pagamentos |
| **Notifications API** | 5004 | Envio de notificações |

### 🔄 Fluxos de Eventos

#### **Cadastro de Usuário**
```
1. POST /api/auth/signup → UsersAPI
2. UserCreatedEvent → RabbitMQ
3. NotificationsAPI → Email de boas-vindas
```

#### **Compra de Jogo**
```
1. POST /api/games/purchase → CatalogAPI
2. OrderPlacedEvent → RabbitMQ
3. PaymentsAPI → Processa pagamento
4. PaymentProcessedEvent → RabbitMQ
5. CatalogAPI → Adiciona jogo à biblioteca (se aprovado)
6. NotificationsAPI → Email de confirmação
```

### 🛠️ Comandos Úteis

```bash
# Parar todos os serviços
docker-compose down

# Parar e remover volumes (limpa dados)
docker-compose down -v

# Rebuild apenas uma API
docker-compose up -d --build users-api

# Ver status dos containers
docker-compose ps

# Entrar em um container
docker exec -it fcg-users-api bash

# Ver logs em tempo real
docker-compose logs -f
```

### 🔧 Desenvolvimento Local

Para rodar uma API localmente (fora do Docker):

```bash
# Subir apenas infraestrutura
docker-compose up -d sqlserver rabbitmq

# Rodar API localmente
cd FCG.Api.Users/src/FCG.Api.Users
dotnet run
```

### 📦 Build de Produção

Os Dockerfiles usam **multi-stage builds** otimizados:
- **Stage 1 (build)**: SDK .NET 8.0 para compilação
- **Stage 2 (publish)**: Publicação Release otimizada
- **Stage 3 (final)**: Runtime .NET 8.0 (imagem menor)

### 🐛 Troubleshooting

**APIs não iniciam:**
```bash
# Verificar se SQL Server está saudável
docker-compose ps
docker logs fcg-sqlserver

# Verificar se RabbitMQ está saudável
docker logs fcg-rabbitmq
```

**Erro de conexão entre APIs:**
```bash
# Verificar network
docker network inspect tc_fcg-network

# Testar conectividade
docker exec fcg-catalog-api ping users-api
```

**Limpar tudo e recomeçar:**
```bash
docker-compose down -v
docker system prune -a
docker-compose up -d --build
```

### 📝 Variáveis de Ambiente

Todas as configurações sensíveis devem estar no arquivo `.env`:

- `JWT_AUTHORITY`: URL do Cognito User Pool
- `AWS_*`: Credenciais AWS
- `COGNITO_*`: Configurações do Cognito
- `ADMIN_*`: Credenciais do usuário admin inicial

### 🔐 Segurança

⚠️ **IMPORTANTE**: 
- Nunca commite o arquivo `.env` com credenciais reais
- Use secrets do Docker Swarm/Kubernetes em produção
- Troque a senha do SQL Server (`SA_PASSWORD`)
- Use HTTPS em produção (configure certificados)

### 📊 Monitoramento

Acesse as interfaces web:
- **RabbitMQ Management**: http://localhost:15672 (guest/guest)
- **Swagger APIs**: http://localhost:500[1-4]/swagger
