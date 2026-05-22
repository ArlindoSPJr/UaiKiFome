# UaiKiFome — Backend

Backend REST de uma plataforma de delivery que conecta clientes, restaurantes e entregadores. Desenvolvido com Node.js + Express + TypeScript + TypeORM + PostgreSQL.

> Documentação completa do domínio em [`docs/proposta.md`](docs/proposta.md).

---

## Pré-requisitos

- [Node.js](https://nodejs.org) 18+
- [Docker](https://www.docker.com) (para o banco de dados)

---

## Como iniciar

**1. Clone o repositório e instale as dependências**
```bash
git clone <url-do-repositorio>
cd uaikifome
npm install
```

**2. Configure as variáveis de ambiente**
```bash
cp .env.example .env
```
Edite o `.env` e defina um valor para `JWT_SECRET`.

**3. Suba o banco de dados**
```bash
docker compose up -d
```

**4. Inicie o servidor**
```bash
npm run dev
```

O servidor estará disponível em `http://localhost:3000`. O TypeORM cria as tabelas automaticamente na primeira execução.

---

## Fluxo básico de uso

```
POST /auth/register   → criar conta (role: restaurant | client | delivery)
POST /auth/login      → obter token JWT
```

Use o token no header de todas as demais requisições:
```
Authorization: Bearer <token>
```

Importe `postman_collection.json` no Postman para ter todos os endpoints prontos.

---

<<<<<<< HEAD
## Endpoints

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| `POST` | `/auth/register` | Não | Criar conta |
| `POST` | `/auth/login` | Não | Autenticar e receber token |
| `PATCH` | `/users/me` | Sim | Atualizar próprios dados |
| `DELETE` | `/users/me` | Sim | Deletar própria conta |
| `POST` | `/restaurants` | Sim | Criar restaurante (`restaurant`) |
| `POST` | `/restaurants/:id/menu` | Sim | Adicionar item ao cardápio (`restaurant`) |
| `GET` | `/restaurants/:id/menu` | Sim | Listar cardápio |
| `POST` | `/orders` | Sim | Criar pedido (`client`) |
| `GET` | `/orders` | Sim | Listar pedidos |
| `GET` | `/orders/:id` | Sim | Buscar pedido |
| `PATCH` | `/orders/:id/status` | Sim | Atualizar status do pedido |

### Fluxo de status do pedido

```
CRIADO → ACEITO (restaurant) → ENTREGADOR_DESIGNADO (delivery) → EM_ENTREGA (delivery) → ENTREGUE (delivery)
```

---

=======
>>>>>>> b492e4c7ef41acbd40a05a66e4745746d858e652
## Scripts

```bash
npm run dev        # desenvolvimento com hot-reload
npm run build      # build para produção
npm start          # iniciar build de produção
```
