# Documento de Proposta — UaiKiFome

**Disciplina:** Projeto Integrador — PUC Minas  
**Aluno:** Arlindo Junior  
**Data:** 08/05/2026

---

## 1. Descrição do Domínio

**UaiKiFome** é uma plataforma mobile de delivery de comida que conecta clientes, restaurantes e entregadores. O nome une a expressão mineira "Uai" com "Ki Fome" (que fome), posicionando o produto como uma solução regional e acessível.

O sistema é composto por um único aplicativo Flutter com controle de acesso por perfil de usuário (`role`), um backend REST em Node.js e um middleware orientado a mensagens (RabbitMQ) para comunicação assíncrona entre os componentes.

O fluxo central da plataforma é o ciclo de vida de um pedido:

```
CRIADO → ACEITO → ENTREGADOR_DESIGNADO → EM_ENTREGA → ENTREGUE
```

Cada transição de estado gera um evento de domínio publicado no RabbitMQ, consumido por workers que notificam os usuários em tempo real via WebSocket.

---

## 2. Justificativa

O domínio de delivery foi escolhido pelos seguintes motivos:

- **Riqueza em eventos assíncronos:** o fluxo de um pedido possui 5 transições de estado bem definidas, cada uma com atores e responsabilidades distintos — cenário ideal para a arquitetura orientada a eventos com MOM exigida pela disciplina.
- **Dois perfis arquiteturais claros:** o restaurante atua como *produtor* (disponibiliza cardápio e processa pedidos) e o cliente como *consumidor* (realiza pedidos e recebe o produto), satisfazendo diretamente o requisito de dois perfis.
- **Complexidade adequada:** o domínio é rico o suficiente para justificar o uso de RabbitMQ, WebSocket e Flutter, mas viável para desenvolvimento individual ao longo das 4 sprints.
- **Relevância prática:** plataformas de delivery são amplamente conhecidas, facilitando a validação das funcionalidades e a comunicação dos requisitos.

---

## 3. Perfis de Usuário

### Cliente (Consumidor)

O cliente é o usuário final da plataforma. Suas responsabilidades e funcionalidades são:

- Visualizar restaurantes disponíveis e seus cardápios
- Criar pedidos com múltiplos itens
- Acompanhar o status do pedido em tempo real via WebSocket
- Consultar histórico de pedidos realizados

### Restaurante (Prestador de Serviço)

O restaurante é o produtor de serviços da plataforma. Suas responsabilidades e funcionalidades são:

- Cadastrar e gerenciar o perfil do restaurante
- Gerenciar o cardápio: adicionar, editar e desativar itens (nome, descrição, preço, disponibilidade)
- Receber notificações de novos pedidos em tempo real
- Aceitar ou rejeitar pedidos recebidos
- Acompanhar o status de pedidos em andamento

> **Entregador:** terceiro ator operacional que aceita ordens de entrega disponíveis e atualiza o status do pedido até a conclusão. Utiliza o mesmo aplicativo com acesso restrito às funcionalidades de entrega via controle de `role`.

---

## 4. Principais Funcionalidades

| Funcionalidade | Perfil |
|---|---|
| Cadastro de restaurante com endereço e descrição | Restaurante |
| Gerenciamento de cardápio (CRUD de itens) | Restaurante |
| Criação de pedido com múltiplos itens e endereço de entrega | Cliente |
| Consulta de pedidos por restaurante, cliente ou status | Ambos |
| Atualização de status do pedido (`PATCH /orders/:id/status`) | Restaurante / Entregador |
| Notificações em tempo real via WebSocket | Ambos |
| Publicação de eventos de domínio no RabbitMQ | Backend |

---

## 5. Stack Tecnológica

| Componente | Tecnologia |
|---|---|
| App Mobile | Flutter / Dart |
| Backend | Node.js + Express + TypeScript |
| ORM | TypeORM |
| Banco de Dados | PostgreSQL |
| Middleware (MOM) | RabbitMQ |
| Comunicação em tempo real | WebSocket |
