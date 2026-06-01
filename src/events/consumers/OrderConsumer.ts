import { ConsumeMessage } from "amqplib";
import { getRabbitMQChannel, QUEUES, ROUTING_KEYS } from "../../config/rabbitmq";
import { NotificationService } from "../../services/NotificationService";
import { UserRepository } from "../../repositories/UserRepository";
import { RestaurantRepository } from "../../repositories/RestaurantRepository";
import { UserRole } from "../../entities/User";

const notificationService = new NotificationService();

// Mensagem in-app exibida ao restaurante para cada tipo de evento recebido na fila restaurant.
const RESTAURANT_MESSAGES: Record<string, string> = {
  [ROUTING_KEYS.orderCreated]: "Novo pedido recebido",
  [ROUTING_KEYS.orderDeliveryAssigned]: "Entrega aceita — entregador a caminho da retirada",
  [ROUTING_KEYS.orderDelivered]: "Pedido finalizado",
};

// Mensagem in-app exibida ao cliente para cada tipo de evento recebido na fila client.
const CLIENT_MESSAGES: Record<string, string> = {
  [ROUTING_KEYS.orderAccepted]: "Seu pedido foi aceito pelo restaurante",
  [ROUTING_KEYS.orderDeliveryAssigned]: "Um entregador foi designado e está indo retirar seu pedido",
  [ROUTING_KEYS.orderInDelivery]: "Seu pedido saiu para entrega",
  [ROUTING_KEYS.orderDelivered]: "Pedido entregue!",
};

/** Log padronizado de recebimento de mensagem por um consumer. */
function logReceived(queue: string, payload: Record<string, unknown>): void {
  console.log(
    `[consumer:${queue}] ${new Date().toISOString()} » mensagem recebida\n` +
      `  ├─ type    : ${payload.type ?? "(sem type)"}\n` +
      `  └─ payload : ${JSON.stringify(payload)}`
  );
}

/** Log padronizado de notificação criada com sucesso. */
function logNotified(queue: string, type: string, userId: string, orderId: string, message: string): void {
  console.log(
    `[consumer:${queue}] notificação criada\n` +
      `  ├─ destinatário (userId) : ${userId}\n` +
      `  ├─ pedido (orderId)      : ${orderId}\n` +
      `  ├─ type                  : ${type}\n` +
      `  └─ message               : "${message}"`
  );
}

export async function startConsumers(): Promise<void> {
  const channel = await getRabbitMQChannel();

  // ── Fila: restaurant_notifications ──────────────────────────────────────────
  // Eventos: order.created, order.delivery_assigned, order.delivered
  // Destinatário: o usuário dono do restaurante (restaurant.userId)
  channel.consume(QUEUES.restaurant, async (msg: ConsumeMessage | null) => {
    if (!msg) return;
    let payload: Record<string, unknown> = {};
    try {
      payload = JSON.parse(msg.content.toString());
      logReceived(QUEUES.restaurant, payload);

      const type = (payload.type as string) ?? ROUTING_KEYS.orderCreated;
      const orderId = payload.orderId as string;
      const restaurantId = payload.restaurantId as string;

      const message = RESTAURANT_MESSAGES[type];
      if (!message) {
        console.warn(`[consumer:${QUEUES.restaurant}] type não mapeado, ignorando: ${type}`);
        channel.ack(msg);
        return;
      }

      const restaurant = await RestaurantRepository.findOne({ where: { id: restaurantId } });
      if (!restaurant) throw new Error(`Restaurante não encontrado: ${restaurantId}`);

      await notificationService.create({ userId: restaurant.userId, type, message, orderId });
      logNotified(QUEUES.restaurant, type, restaurant.userId, orderId, message);

      channel.ack(msg);
      console.log(`[consumer:${QUEUES.restaurant}] ✓ ${type} processado — pedido ${orderId} (ack)`);
    } catch (err) {
      console.error(
        `[consumer:${QUEUES.restaurant}] ✗ erro ao processar ${payload.type ?? "evento"}:`,
        err
      );
      channel.nack(msg, false, false);
      console.log(`[consumer:${QUEUES.restaurant}] mensagem descartada (nack, requeue=false)`);
    }
  });

  // ── Fila: client_notifications ──────────────────────────────────────────────
  // Eventos: order.accepted, order.delivery_assigned, order.in_delivery, order.delivered
  // Destinatário: o cliente do pedido (clientId)
  channel.consume(QUEUES.client, async (msg: ConsumeMessage | null) => {
    if (!msg) return;
    let payload: Record<string, unknown> = {};
    try {
      payload = JSON.parse(msg.content.toString());
      logReceived(QUEUES.client, payload);

      const type = (payload.type as string) ?? ROUTING_KEYS.orderAccepted;
      const orderId = payload.orderId as string;
      const clientId = payload.clientId as string;

      const message = CLIENT_MESSAGES[type];
      if (!message) {
        console.warn(`[consumer:${QUEUES.client}] type não mapeado, ignorando: ${type}`);
        channel.ack(msg);
        return;
      }

      await notificationService.create({ userId: clientId, type, message, orderId });
      logNotified(QUEUES.client, type, clientId, orderId, message);

      channel.ack(msg);
      console.log(`[consumer:${QUEUES.client}] ✓ ${type} processado — pedido ${orderId} (ack)`);
    } catch (err) {
      console.error(`[consumer:${QUEUES.client}] ✗ erro ao processar ${payload.type ?? "evento"}:`, err);
      channel.nack(msg, false, false);
      console.log(`[consumer:${QUEUES.client}] mensagem descartada (nack, requeue=false)`);
    }
  });

  // ── Fila: delivery_notifications ────────────────────────────────────────────
  // Evento: order.accepted → broadcast para todos os entregadores ativos
  channel.consume(QUEUES.delivery, async (msg: ConsumeMessage | null) => {
    if (!msg) return;
    let payload: Record<string, unknown> = {};
    try {
      payload = JSON.parse(msg.content.toString());
      logReceived(QUEUES.delivery, payload);

      const type = (payload.type as string) ?? ROUTING_KEYS.orderAccepted;
      const orderId = payload.orderId as string;

      const deliveryUsers = await UserRepository.find({ where: { role: UserRole.DELIVERY } });
      console.log(
        `[consumer:${QUEUES.delivery}] broadcast para ${deliveryUsers.length} entregador(es)`
      );

      await Promise.all(
        deliveryUsers.map((user) =>
          notificationService.create({
            userId: user.id,
            type,
            message: "Novo pedido disponível para entrega",
            orderId,
          })
        )
      );

      channel.ack(msg);
      console.log(`[consumer:${QUEUES.delivery}] ✓ ${type} processado — pedido ${orderId} (ack)`);
    } catch (err) {
      console.error(`[consumer:${QUEUES.delivery}] ✗ erro ao processar ${payload.type ?? "evento"}:`, err);
      channel.nack(msg, false, false);
      console.log(`[consumer:${QUEUES.delivery}] mensagem descartada (nack, requeue=false)`);
    }
  });

  console.log("Workers RabbitMQ iniciados — aguardando mensagens");
}
