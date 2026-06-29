# Relatório Técnico Final — UaiKiFome

**Plataforma de delivery orientada a eventos**

---

## Resumo

Este relatório descreve a arquitetura, as decisões de projeto e as lições aprendidas no desenvolvimento do **UaiKiFome**, uma plataforma de delivery composta por um backend Node.js/TypeScript e um aplicativo Flutter multiplataforma. O sistema foi construído sobre quatro pilares arquiteturais estudados na disciplina: **Clean Architecture** (organização do backend em camadas com dependências direcionadas à regra de negócio), **REST** (interface HTTP stateless autenticada por JWT), **EDA — Event-Driven Architecture** (o ciclo de vida do pedido emite eventos de domínio) e **MOM — Message-Oriented Middleware** (RabbitMQ como barramento assíncrono de mensagens entre produtores e consumidores). O resultado é um fluxo de pedido desacoplado e resiliente, no qual a criação de uma solicitação pelo cliente propaga notificações ao restaurante e ao entregador sem acoplamento direto entre esses módulos, e o cliente recebe atualizações em tempo real por WebSocket.

---

## 1. Introdução e objetivo

O UaiKiFome modela uma plataforma de entrega de comida com três atores: **cliente** (faz pedidos), **restaurante** (gerencia cardápio e aceita pedidos) e **entregador** (assume e realiza entregas). O papel de cada usuário é representado pelo seu cargo dentro do aplicativo.

O elemento central do domínio é o **pedido (`Order`)**, cujo ciclo de vida é uma máquina de estados estrita:

```
CRIADO → ACEITO → ENTREGADOR_DESIGNADO → EM_ENTREGA → ENTREGUE
```

Cada estado admite exatamente uma transição válida (`isValidTransition`), e qualquer tentativa de transição inválida é rejeitada com HTTP `422`. Essa máquina de estados é o "gatilho" de toda a comunicação assíncrona: **cada transição de status emite um evento de domínio** no middleware de mensageria, que por sua vez aciona os módulos interessados.

O objetivo técnico do projeto foi demonstrar, na prática, como combinar uma organização de código limpa (Clean Architecture) com uma interface REST e uma espinha dorsal orientada a eventos (EDA sobre MOM), entregando um fluxo de ponta a ponta verificável: **cliente cria solicitação → backend publica evento no MOM → prestador é notificado → prestador aceita → cliente é notificado da atualização.**

---

## 2. Visão geral da arquitetura

O sistema divide-se em três grandes blocos: o **backend** (API + barramento de eventos), o **armazenamento** (PostgreSQL) e o **cliente Flutter**. A figura abaixo resume os componentes e os caminhos de comunicação — síncrono (REST) e assíncrono (MOM/WebSocket):

```
                        ┌────────────────────────────────────────────┐
                        │              App Flutter (cliente)           │
                        │  Telas → Providers → API (Dio) / WebSocket   │
                        │  papéis: cliente · restaurante · entregador  │
                        └───────────────┬───────────────┬─────────────┘
                          REST (HTTP/JWT)│               │ WebSocket (tempo real)
                                         ▼               ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              Backend Node/Express                               │
│                                                                                │
│   Routes → Controllers → Services → Repositories → Entities (TypeORM)          │
│                              │                                                  │
│                              │ publica evento de domínio                        │
│                              ▼                                                  │
│            OrderPublisher ──► RabbitMQ (exchange topic "uaikifome")            │
│                                     │  routing keys: order.*                    │
│                  ┌──────────────────┼─────────────────────┐                    │
│                  ▼                  ▼                     ▼                     │
│        restaurant_notif.     client_notif.        delivery_notif.   (filas)    │
│                  └──────────────────┴─────────────────────┘                    │
│                                     │ OrderConsumer (workers)                   │
│                                     ▼                                           │
│                        NotificationService → tabela notifications              │
│                                     │                                           │
│                                     ▼ notifyUser / notifyRole                   │
│                              WebSocket Server ──► clientes conectados           │
└───────────────────────────────────┬────────────────────────────────────────┘
                                     ▼
                              PostgreSQL (TypeORM)
```

**Tecnologias principais:** Node.js, Express, TypeScript, TypeORM, PostgreSQL, RabbitMQ , WebSocket, Flutter. A orquestração é feita via Docker Compose: o `docker-compose.yml` sobe **três serviços** — o **backend** (API + WebSocket, porta `3000`), o **PostgreSQL** (porta `5433` no host) e o **RabbitMQ** (portas `5672` e `15672`). Assim, todo o lado servidor é levantado com um único `docker compose up -d --build`, sem necessidade de instalar Node.js ou configurar `.env` manualmente. A **única** parte que roda separadamente, via terminal, é o **aplicativo Flutter (frontend)**, que se conecta ao backend exposto em `http://localhost:3000`.

A inicialização do backend (`src/server.ts`) segue uma ordem deliberada: (1) conectar ao banco (`AppDataSource.initialize`), (2) iniciar os consumidores de mensagens (`startConsumers`), e só então (3) subir o servidor HTTP e anexar o servidor WebSocket (`initWsServer`). Essa sequência garante que nenhuma requisição seja atendida antes de o sistema estar apto a produzir e consumir eventos.

---

## 3. Clean Architecture e decisões de design

O backend adota uma organização em camadas com uma direção de dependência clara, do mais externo (transporte) ao mais interno (domínio):

```
Routes → Controllers → Services → Repositories → Entities
```

- **Routes** (`src/routes/`): agrupam endpoints e aplicam middlewares transversais, como `authenticate`.
- **Controllers** (`src/controllers/`): validam o formato da requisição e delegam; **não contêm regra de negócio**. Ex.: `OrderController.updateStatus` apenas extrai `status` do corpo e repassa ao serviço.
- **Services** (`src/services/`): concentram **toda** a lógica de negócio. Lançam erros no formato `{ status, message }`, convertidos em respostas HTTP pelo middleware `errorHandler` (`src/middlewares/errorHandler.ts`).
- **Repositories** (`src/repositories/`): estendem o repositório do TypeORM com consultas específicas via `.extend()` (ex.: `OrderRepository.findByFilters`, `findWithItems`).
- **Entities** (`src/entities/`): modelos de domínio mapeados pelo TypeORM.

Algumas **convenções de projeto** reforçam a robustez:

1. **IDs sempre gerados pelo servidor** — todos os identificadores são `@PrimaryGeneratedColumn("uuid")`; nenhum controller aceita `id` no corpo de criação, evitando conflitos e injeção de identificadores.
2. **Identidade a partir do token, não do corpo** — o middleware `authenticate` injeta `req.user = { id, role }`; os controllers usam `req.user.id` em vez de confiar em um `clientId` enviado pelo cliente.
3. **Erros centralizados** — o padrão `{ status, message }` desacopla a sinalização de erro do mecanismo HTTP, mantendo os serviços agnósticos quanto ao Express.

O principal **benefício** observado foi a testabilidade conceitual e a localização de mudanças: alterações de regra (como a baixa de estoque, Seção 8) ficam contidas no Service, sem vazar para controllers ou rotas. O principal **trade-off** é a verbosidade — para cada recurso há quatro artefatos (rota, controller, service, repository), o que aumenta o atrito em mudanças triviais, mas paga-se esse custo com clareza de responsabilidades.

---

## 4. Interface REST

A API expõe recursos REST sob `src/app.ts`, montando os roteadores `/auth`, `/users`, `/restaurants`, `/orders` e `/notifications`, além de um endpoint `/health`. O acesso é **stateless**: após `POST /auth/login`, o cliente recebe um JWT e o envia em cada requisição no cabeçalho `Authorization: Bearer <token>`.

O recurso de pedidos (`src/routes/order.routes.ts`) ilustra o estilo:

- `POST /orders` — cria um pedido (apenas role `client`).
- `GET /orders` — lista pedidos, com filtros por `restaurantId`, `clientId`, `deliveryPersonId` e `status`.
- `GET /orders/:id` — recupera um pedido.
- `PATCH /orders/:id/status` — transita o status do pedido.

O uso de **códigos de status HTTP** é semântico e consistente com a teoria REST: `201` para criação, `403` quando o papel do usuário não autoriza a transição, `422` para transição de estado inválida e `404` para recurso inexistente. A combinação de verbos HTTP com uma modelagem orientada a recursos torna a interface previsível e cacheável, características centrais do estilo arquitetural REST.

---

## 5. EDA e MOM: o núcleo assíncrono

O centro da arquitetura é a comunicação **orientada a eventos** sobre um **middleware de mensagens (RabbitMQ)**. Em vez de o serviço de pedidos chamar diretamente os módulos de notificação do restaurante, do cliente e do entregador, ele apenas **publica um evento de domínio** e segue adiante; quem estiver interessado reage de forma independente.

### 5.1 Topologia de mensageria

A configuração (`src/config/rabbitmq.ts`) declara um **exchange do tipo `topic`** chamado `uaikifome` (durável) e três filas duráveis, uma por destinatário:

- `restaurant_notifications`
- `client_notifications`
- `delivery_notifications`

As **routing keys** representam os eventos do ciclo de vida do pedido: `order.created`, `order.accepted`, `order.delivery_assigned`, `order.in_delivery` e `order.delivered`. Os *bindings* roteiam cada evento para os interessados, por exemplo:

- `order.created` → fila do **restaurante** (há um novo pedido a aceitar);
- `order.accepted` → filas do **cliente** (pedido aceito) e do **entregador** (broadcast de pedido disponível);
- `order.delivery_assigned`, `order.in_delivery`, `order.delivered` → fila do **cliente** (acompanhamento), com o restaurante também notificado da designação e da entrega final.

### 5.2 Produtores e consumidores

A publicação é encapsulada em `src/events/publishers/OrderPublisher.ts`. Cada função (`publishOrderCreated`, `publishOrderAccepted`, etc.) monta um payload com `type`, `orderId` e os identificadores relevantes, e o envia com a flag **`persistent: true`** — garantindo que a mensagem sobreviva a reinícios do broker. É fundamental notar que o **produtor não conhece os consumidores**: ele só sabe o nome do evento.

Do outro lado, `src/events/consumers/OrderConsumer.ts` registra um *worker* por fila. Cada worker desserializa a mensagem, traduz o `type` em uma mensagem amigável (mapas `RESTAURANT_MESSAGES`/`CLIENT_MESSAGES`), resolve o destinatário (o dono do restaurante, o cliente, ou — no caso do entregador — **todos** os usuários com role `delivery`, em *broadcast*) e persiste uma `Notification` via `NotificationService`. O processamento usa **confirmação explícita**: `channel.ack(msg)` em caso de sucesso e `channel.nack(msg, false, false)` em caso de erro, descartando a mensagem problemática sem reenfileirá-la indefinidamente (evitando *poison messages* em laço).

### 5.3 Resiliência

A conexão com o RabbitMQ implementa **retry com backoff** (`connect`, 5 tentativas com intervalo de 3s em `rabbitmq.ts`), tolerando o cenário comum em que o broker ainda está subindo quando a aplicação inicia (típico em ambientes Docker). Filas duráveis + mensagens persistentes + ack manual formam, em conjunto, uma entrega **ao menos uma vez** com tolerância a falhas.

### 5.4 Por que EDA/MOM em vez de chamadas síncronas

Se o serviço de pedidos invocasse diretamente os notificadores, cada novo destinatário (por exemplo, o entregador adicionado posteriormente ao projeto) exigiria alterar o código do produtor, e uma falha temporária de um notificador poderia derrubar a operação de pedido. Com EDA sobre MOM, **adicionar um novo consumidor é apenas criar uma nova fila e um novo binding** — o produtor permanece intocado. Ganha-se baixo acoplamento, escalabilidade (workers podem ser paralelizados) e resiliência (mensagens aguardam na fila se um consumidor estiver indisponível).

---

## 6. Notificação em tempo real (WebSocket)

O MOM resolve a entrega **assíncrona e persistente** das notificações, mas o aplicativo também precisa de **atualização imediata** da tela quando o status muda. Para isso há uma segunda camada: um servidor WebSocket (`src/websocket/wsServer.ts`) que autentica a conexão por JWT (token na query string) e mantém um mapa de usuários conectados com seu papel.

Em `OrderService.updateStatus`, após persistir a transição, o serviço envia um payload `order_status_updated` via:

- `notifyUser(userId, payload)` — para o cliente e o restaurante donos do pedido, e para o entregador designado;
- `notifyRole("delivery", payload)` — para **todos** os entregadores conectados quando surge um pedido `ACEITO` disponível.

Assim, o sistema combina **duas camadas complementares**: o MOM produz notificações *duráveis* (histórico em banco, recuperável depois) e o WebSocket entrega atualizações *efêmeras* e instantâneas à interface.

---

## 7. Fluxo de ponta a ponta

O roteiro de demonstração exercita exatamente os padrões descritos. Cada passo está ancorado no código:

1. **Cliente cria a solicitação** — `POST /orders` → `OrderService.create` valida itens, calcula total, dá baixa no estoque (em transação) e publica `order.created` no exchange `uaikifome`.
2. **Backend publica no MOM** — `OrderPublisher.publishOrderCreated` emite o evento; o produtor não conhece o destinatário.
3. **Restaurante é notificado** — o worker da fila `restaurant_notifications` consome `order.created`, grava uma `Notification` para o dono do restaurante; a UI do restaurante exibe o pedido pendente.
4. **Restaurante aceita** — `PATCH /orders/:id/status` para `ACEITO` → publica `order.accepted`, roteado para as filas do cliente e do entregador.
5. **Entregador é notificado** — o worker `delivery_notifications` faz *broadcast* para todos os entregadores; em paralelo, `notifyRole` empurra a atualização via WebSocket aos entregadores conectados.
6. **Entregador aceita / inicia a entrega** — transições `ENTREGADOR_DESIGNADO` e `EM_ENTREGA` (o entregador se auto-designa, `deliveryPersonId = req.user.id`), publicando `order.delivery_assigned` e `order.in_delivery`.
7. **Cliente é notificado da atualização** — o worker `client_notifications` persiste a notificação e o WebSocket entrega `order_status_updated`, fazendo a tela de acompanhamento do cliente refletir o novo status sem recarregar.

---

## 8. Decisões de design adicionais

1. **Baixa automática de estoque em transação** — `OrderService.create` envolve a criação do pedido e o decremento de estoque dos itens em uma única `AppDataSource.transaction`, validando estoque suficiente (erro `400` caso contrário) e marcando o item como indisponível ao zerar. Garante consistência: ou o pedido é criado e o estoque baixado, ou nada acontece.
2. **Auto-designação do entregador** — em vez de o restaurante escolher um entregador, qualquer entregador disponível "reivindica" o pedido aceito, simplificando a coordenação e aproveitando o broadcast do MOM.
3. **Dupla camada de notificação** — MOM (persistente, histórico) + WebSocket (efêmero, instantâneo), cada um cobrindo uma necessidade distinta.

---

## 9. Dificuldades encontradas e soluções adotadas

1. **Ordem de inicialização e disponibilidade do broker** — com o backend também conteinerizado, o serviço podia subir antes de o Postgres e o RabbitMQ estarem prontos. *Solução:* no `docker-compose.yml`, o serviço `backend` declara `depends_on` com `condition: service_healthy` para ambos (cada um com seu `healthcheck`), aguardando-os ficarem saudáveis; complementarmente, a aplicação faz retry com backoff na conexão e segue uma sequência de boot explícita (banco → consumidores → HTTP/WS).
2. **Consistência estoque × pedido** — risco de baixar estoque sem criar o pedido (ou vice-versa). *Solução:* transação única envolvendo ambas as operações.

---

## 10. Reflexão sobre os padrões estudados

O projeto evidenciou que os quatro padrões não competem, mas se **complementam em camadas de responsabilidade distintas**:

- A **Clean Architecture** organizou o "dentro" do backend, mantendo a regra de negócio isolada de detalhes de transporte e persistência. Foi ela que permitiu introduzir a baixa de estoque e o enriquecimento de resposta sem efeito colateral em controllers ou rotas.
- O **REST** definiu a fronteira síncrona e previsível com o cliente — operações de comando e consulta com semântica HTTP clara e autenticação stateless.
- A **EDA** modelou o sistema em termos de **eventos de domínio** (as transições do pedido), o que se mostrou uma forma natural de pensar um fluxo de delivery, intrinsecamente reativo.
- O **MOM** materializou a EDA com garantias operacionais (durabilidade, ack, retry) e desacoplamento real entre produtor e consumidores.

O custo dessa combinação é a **complexidade operacional** (um broker a mais para orquestrar, depurar e monitorar) e a **eventual consistência** entre o estado persistido e as notificações. Para um domínio com múltiplos atores reagindo a um mesmo fato, contudo, o benefício de baixo acoplamento e extensibilidade superou esse custo — adicionar o ator "entregador" ao longo do projeto exigiu apenas uma nova fila, um binding e um consumidor, sem tocar no produtor de eventos.

---

## 11. Conclusão

O UaiKiFome cumpriu o objetivo de demonstrar, de ponta a ponta, uma arquitetura que une organização de código (Clean Architecture), interface de serviço (REST) e integração assíncrona (EDA sobre MOM), complementada por notificações em tempo real via WebSocket. O fluxo central — cliente cria solicitação, evento é publicado no middleware, prestadores são notificados, o entregador aceita e o cliente é atualizado — funciona de forma desacoplada e resiliente. As dificuldades enfrentadas (portabilidade web, cobertura de notificações, consistência transacional, inicialização em ambiente conteinerizado) foram resolvidas com mudanças localizadas, o que valida, na prática, as qualidades de manutenibilidade e extensibilidade buscadas com os padrões estudados.

---

## Referências Bibliográficas

> *(preencher conforme a ementa da disciplina ou fontes acadêmicas indexadas — mínimo 3)*

1. *(Flutter - lab07_Flutter)*
2. *(Message-Oriented Middleware - lab08 - Redis e RabbitMQ)*
3. *(WebSocket - https://developer.mozilla.org/pt-BR/docs/Web/API/WebSocket)*
