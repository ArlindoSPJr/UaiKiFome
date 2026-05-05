# UaiKiFome — Design de Domínio

**Data:** 2026-05-04
**Disciplina:** Projeto Integrador — PUC Minas
**Sprint 1 deadline:** 2026-05-11

---

## 1. Visão Geral do Domínio

**UaiKiFome** é uma plataforma de delivery de comida focada em restaurantes e lanchonetes. O nome une a expressão mineira "Uai" com "Ki Fome" (que fome), posicionando o produto como uma solução regional e acessível.

O sistema conecta três atores operacionais mapeados em dois papéis arquiteturais conforme exigido pelo enunciado:

| Ator | Papel arquitetural | O que recebe da plataforma |
|---|---|---|
| Restaurante (Host) | Produtor | Pedidos dos clientes |
| Cliente | Consumidor | Comida entregue no endereço |
| Entregador | Consumidor | Ordens de entrega disponíveis |

**Justificativa do mapeamento:** tanto o cliente quanto o entregador são consumidores de serviços produzidos pelo restaurante — um consome o produto (comida), o outro consome a demanda de entrega. O restaurante é o único ator que produz e disponibiliza recursos na plataforma, satisfazendo o requisito de dois perfis (produtor/consumidor) com riqueza de domínio.

---

## 2. Fluxo Principal de um Pedido

```
CRIADO → ACEITO → ENTREGADOR_DESIGNADO → EM_ENTREGA → ENTREGUE
```

| Transição | Ator responsável |
|---|---|
| `CRIADO` | Cliente cria o pedido via app |
| `ACEITO` | Restaurante aceita o pedido via app |
| `ENTREGADOR_DESIGNADO` | Entregador aceita a ordem de entrega disponível via app |
| `EM_ENTREGA` | Entregador inicia a entrega via app |
| `ENTREGUE` | Entregador confirma a entrega via app |

Cada transição de estado gera um evento de domínio publicado no RabbitMQ.

---

## 3. Arquitetura Técnica

### 3.1 Abordagem Escolhida

**Monolito REST com RabbitMQ lateral.** Um único backend Express expõe os endpoints REST. Nas operações de negócio, o backend publica eventos no RabbitMQ. Workers Node.js separados consomem os eventos e disponibilizam atualizações para os apps Flutter via polling HTTP (Sprints 1–2), com possibilidade de evolução para WebSocket na Sprint 3.

Essa abordagem respeita o ritmo das sprints: a Sprint 1 entrega o backend funcional sem dependência do MOM, e a Sprint 2 adiciona o RabbitMQ de forma incremental.

### 3.2 Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────┐
│                      Flutter Apps                        │
│  [App Cliente]    [App Entregador]   [App Restaurante]   │
└────────┬──────────────┬──────────────────┬──────────────┘
         │ HTTP/REST     │ HTTP/REST         │ HTTP/REST
         ▼              ▼                  ▼
┌─────────────────────────────────────────────────────────┐
│             Backend Express + TypeORM                    │
│                  (Node.js + TypeScript)                  │
│                                                         │
│   Routes → Controllers → Services → Repositories        │
│                      │                                  │
│                publica eventos (AMQP)                   │
└──────────────────────┬──────────────────────────────────┘
                       │ AMQP
                       ▼
           ┌───────────────────────┐
           │       RabbitMQ        │
           │   exchanges / queues  │
           └──────────┬────────────┘
                      │ AMQP
           ┌──────────▼────────────┐
           │   Workers / Consumers │
           │  (processam eventos   │
           │   e notificam apps)   │
           └───────────────────────┘
                      │
           ┌──────────▼────────────┐
           │      PostgreSQL        │
           │     (via TypeORM)     │
           └───────────────────────┘
```

### 3.3 Protocolos de Comunicação

| Camada | Protocolo |
|---|---|
| Apps Flutter ↔ Backend | HTTP/REST (JSON) |
| Backend → RabbitMQ | AMQP (publicação) |
| RabbitMQ → Workers | AMQP (consumo) |
| Workers → Apps | Polling HTTP (Sprint 1–2) / WebSocket (Sprint 3+) |

### 3.4 Stack Tecnológica

| Componente | Tecnologia |
|---|---|
| Backend | Node.js + Express + TypeScript |
| ORM | TypeORM |
| Banco de dados | PostgreSQL |
| MOM | RabbitMQ (Docker) |
| Apps móveis | Flutter / Dart |

---

## 4. Organização do Código — Backend (Clean Architecture)

```
src/
  entities/       # modelos TypeORM (User, Restaurant, MenuItem, Order, OrderItem)
  repositories/   # acesso a dados — interfaces + implementações TypeORM
  services/       # lógica de negócio + publicação de eventos RabbitMQ
  controllers/    # handlers HTTP — recebem request, chamam services
  routes/         # definição e agrupamento de endpoints
  events/
    producers/    # publica eventos no RabbitMQ
    consumers/    # workers que consomem eventos
  config/         # conexão com banco, RabbitMQ, variáveis de ambiente
```

---

## 5. Modelo de Dados

### Entidades

**User**
| Campo | Tipo | Descrição |
|---|---|---|
| id | UUID | Identificador único |
| name | string | Nome completo |
| email | string | Email único |
| password | string | Hash bcrypt |
| role | enum | `restaurant` \| `client` \| `delivery` |
| createdAt | timestamp | Data de criação |

**Restaurant**
| Campo | Tipo | Descrição |
|---|---|---|
| id | UUID | Identificador único |
| userId | UUID (FK) | Dono do restaurante |
| name | string | Nome do restaurante |
| description | string | Descrição |
| address | string | Endereço |

**MenuItem**
| Campo | Tipo | Descrição |
|---|---|---|
| id | UUID | Identificador único |
| restaurantId | UUID (FK) | Restaurante ao qual pertence |
| name | string | Nome do item |
| description | string | Descrição |
| price | decimal | Preço unitário |
| available | boolean | Disponível no cardápio |

**Order**
| Campo | Tipo | Descrição |
|---|---|---|
| id | UUID | Identificador único |
| clientId | UUID (FK) | Cliente que fez o pedido |
| restaurantId | UUID (FK) | Restaurante do pedido |
| deliveryPersonId | UUID (FK) | Entregador designado (nullable) |
| status | enum | `CRIADO` \| `ACEITO` \| `ENTREGADOR_DESIGNADO` \| `EM_ENTREGA` \| `ENTREGUE` |
| total | decimal | Valor total do pedido |
| deliveryAddress | string | Endereço de entrega |
| createdAt | timestamp | Data de criação |
| updatedAt | timestamp | Última atualização |

**OrderItem**
| Campo | Tipo | Descrição |
|---|---|---|
| id | UUID | Identificador único |
| orderId | UUID (FK) | Pedido ao qual pertence |
| menuItemId | UUID (FK) | Item do cardápio |
| quantity | integer | Quantidade |
| unitPrice | decimal | Preço unitário no momento do pedido |

---

## 6. Eventos de Domínio (RabbitMQ)

| Evento | Produzido por | Consumido por | Payload (exemplo) |
|---|---|---|---|
| `order.created` | Backend (ao criar pedido) | App Restaurante | `{ orderId, clientId, restaurantId, items, total }` |
| `order.accepted` | Backend (ao aceitar pedido) | App Cliente | `{ orderId, restaurantId, estimatedTime }` |
| `order.delivery_assigned` | Backend (ao entregador aceitar a entrega) | App Cliente, App Restaurante | `{ orderId, deliveryPersonId }` |
| `order.in_delivery` | Backend (entregador inicia) | App Cliente | `{ orderId, deliveryPersonId }` |
| `order.delivered` | Backend (entregador conclui) | App Cliente, App Restaurante | `{ orderId, deliveredAt }` |

**Exchange:** `uaikifome.orders` (tipo `topic`)
**Routing key:** nome do evento (ex: `order.created`)

---

## 7. Endpoints REST — Sprint 1

Mínimo de 4 endpoints conforme exigido. Os endpoints abaixo cobrem as operações essenciais do domínio:

| Método | Rota | Descrição |
|---|---|---|
| `POST` | `/restaurants` | Cadastrar restaurante |
| `GET` | `/restaurants/:id/menu` | Listar cardápio do restaurante |
| `POST` | `/orders` | Criar pedido |
| `GET` | `/orders/:id` | Consultar pedido por ID |
| `GET` | `/orders` | Listar pedidos (query: `?restaurantId=`, `?clientId=`, `?status=`) |
| `PATCH` | `/orders/:id/status` | Atualizar status do pedido |

---

## 8. Tratamento de Erros

- Validação de entrada nos controllers com retorno `400 Bad Request` e mensagem descritiva
- Transições de status inválidas retornam `422 Unprocessable Entity`
- Recursos não encontrados retornam `404 Not Found`
- Erros internos retornam `500 Internal Server Error` com log no servidor (sem expor stack trace)
- Falha na publicação de evento no RabbitMQ não bloqueia a resposta REST — o evento é descartado com log de erro (tolerância a falha na Sprint 1; pode evoluir para dead-letter queue nas sprints seguintes)

---

## 9. Estratégia de Testes — Sprint 1

- Coleção Postman/Insomnia com todos os endpoints documentados
- Exemplos de requisição e resposta para cada endpoint
- Casos de erro documentados (recurso não encontrado, status inválido)
- Banco de dados SQLite em memória para testes isolados (PostgreSQL para produção)

---

## 10. Cronograma de Sprints

| Sprint | Foco | Prazo |
|---|---|---|
| Sprint 1 | Proposta de domínio + Backend REST funcional | 11/05/2026 |
| Sprint 2 | Integração RabbitMQ + eventos de domínio | 25/05/2026 |
| Sprint 3 | App Flutter — Cliente | 15/06/2026 |
| Sprint 4 | App Flutter — Entregador/Restaurante + integração final | 03/07/2026 |
