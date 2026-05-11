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

## Scripts

```bash
npm run dev        # desenvolvimento com hot-reload
npm run build      # build para produção
npm start          # iniciar build de produção
```
