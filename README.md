# UaiKiFome — Backend

Backend REST de uma plataforma de delivery que conecta clientes, restaurantes e entregadores. Desenvolvido com Node.js + Express + TypeScript + TypeORM + PostgreSQL, com mensageria via RabbitMQ e notificações em tempo real via WebSocket.

> Documentação completa do domínio em [`docs/proposta.md`](docs/proposta.md).

---

## Arquitetura

O lado servidor é composto por três serviços, todos orquestrados pelo `docker-compose.yml`:

- **backend** — API REST + servidor WebSocket (porta `3000`)
- **postgres** — banco de dados PostgreSQL (porta `5433` no host)
- **rabbitmq** — mensageria de eventos de pedido + painel de gerenciamento (portas `5672` e `15672`)

Além disso, o repositório inclui o **aplicativo Flutter** (`flutter_app/`) — o frontend que consome a API. Ele **roda separadamente** (no navegador ou em um dispositivo/emulador mobile) e não faz parte do Docker Compose. Veja [Aplicativo (Flutter)](#aplicativo-flutter).

---

## Pré-requisitos

- [Docker](https://www.docker.com) e Docker Compose
- [Node.js](https://nodejs.org) 20+ — **somente** se for rodar o backend localmente (modo desenvolvimento)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3+ — para rodar o aplicativo (web ou mobile)

---

## Como iniciar

### Opção A — Tudo no Docker (recomendado)

Sobe os três serviços (backend, banco e RabbitMQ) com um único comando. Não é necessário criar `.env` — as variáveis já estão definidas no `docker-compose.yml`.

```bash
git clone <url-do-repositorio>
cd uaikifome
docker compose up -d --build
```

A API ficará disponível em `http://localhost:3000`. O TypeORM cria as tabelas automaticamente na primeira execução (`synchronize: true`).

Para acompanhar os logs do backend:
```bash
docker compose logs -f backend
```

Para derrubar tudo:
```bash
docker compose down
```

## Aplicativo (Flutter)

O frontend fica em [`flutter_app/`](flutter_app/) e roda separadamente do backend. Garanta que o servidor esteja no ar (Opção A ou B) antes de iniciar o app.

### Rodar no navegador (Flutter Web)

```bash
cd flutter_app
flutter pub get
flutter run -d chrome
```

O app detecta a plataforma automaticamente: quando executado na web, aponta para `http://localhost:3000` (API) e `ws://localhost:3000` (WebSocket), conectando-se ao backend local. Não é necessária nenhuma configuração extra.

### Rodar no mobile (emulador/dispositivo)

```bash
cd flutter_app
flutter pub get
flutter run
```

No emulador **Android**, o app usa automaticamente `http://10.0.2.2:3000` para alcançar o backend rodando na máquina host.

---

## Variáveis de ambiente

| Variável | Descrição | Padrão |
|---|---|---|
| `PORT` | Porta da API | `3000` |
| `DB_HOST` | Host do Postgres | `localhost` |
| `DB_PORT` | Porta do Postgres (use `5433` no host) | `5432` |
| `DB_USERNAME` | Usuário do banco | `uaikifome` |
| `DB_PASSWORD` | Senha do banco | `uaikifome123` |
| `DB_DATABASE` | Nome do banco | `uaikifome` |
| `JWT_SECRET` | Segredo para assinatura dos tokens JWT | — |
| `RABBITMQ_URL` | URL de conexão do RabbitMQ | `amqp://guest:guest@localhost:5672` |

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

## Endpoints

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| `POST` | `/auth/register` | Não | Criar conta |
| `POST` | `/auth/login` | Não | Autenticar e receber token |
| `PATCH` | `/users/me` | Sim | Atualizar próprios dados |
| `DELETE` | `/users/me` | Sim | Deletar própria conta |
| `GET` | `/restaurants` | Sim | Listar restaurantes |
| `GET` | `/restaurants/mine` | Sim | Restaurante do usuário logado (`restaurant`) |
| `POST` | `/restaurants` | Sim | Criar restaurante (`restaurant`) |
| `GET` | `/restaurants/:id/menu` | Sim | Listar cardápio |
| `POST` | `/restaurants/:id/menu` | Sim | Adicionar item ao cardápio (`restaurant`) |
| `PATCH` | `/restaurants/:id/menu/:itemId` | Sim | Alternar disponibilidade de item (`restaurant`) |
| `POST` | `/orders` | Sim | Criar pedido (`client`) |
| `GET` | `/orders` | Sim | Listar pedidos |
| `GET` | `/orders/:id` | Sim | Buscar pedido |
| `PATCH` | `/orders/:id/status` | Sim | Atualizar status do pedido |
| `POST` | `/orders/:id/reject` | Sim | Entregador recusa um pedido (`delivery`) |
| `GET` | `/notifications` | Sim | Listar notificações do usuário |

### Fluxo de status do pedido

```
CRIADO → ACEITO (restaurant) → ENTREGADOR_DESIGNADO (delivery) → EM_ENTREGA (delivery) → ENTREGUE (delivery)
```

### Notificações em tempo real (WebSocket)

O backend expõe um servidor WebSocket na mesma porta da API. Conecte-se passando o token JWT na query string:

```
ws://localhost:3000?token=<token>
```

As mudanças de status do pedido geram eventos que são publicados no RabbitMQ e entregues ao cliente conectado via WebSocket.

### RabbitMQ

O painel de gerenciamento fica disponível em `http://localhost:15672` (usuário `guest`, senha `guest`).

---

## Scripts

```bash
npm run dev        # desenvolvimento com hot-reload
npm run build      # build para produção
npm start          # iniciar build de produção
```
