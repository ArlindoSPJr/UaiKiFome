import { getRabbitMQChannel, EXCHANGE, ROUTING_KEYS } from "../../config/rabbitmq";

/**
 * Publica um evento no exchange 'uaikifome' com log detalhado de producer.
 * O log registra timestamp, evento, routing key, exchange e o payload completo,
 * permitindo rastrear cada mensagem emitida no fluxo do pedido.
 */
async function publish(routingKey: string, payload: Record<string, unknown>): Promise<void> {
  const channel = await getRabbitMQChannel();
  const body = JSON.stringify(payload);
  channel.publish(EXCHANGE, routingKey, Buffer.from(body), { persistent: true });
  console.log(
    `[producer] ${new Date().toISOString()} » evento publicado\n` +
      `  ├─ exchange    : ${EXCHANGE}\n` +
      `  ├─ routingKey  : ${routingKey}\n` +
      `  ├─ persistent  : true\n` +
      `  └─ payload     : ${body}`
  );
}

export async function publishOrderCreated(orderId: string, restaurantId: string, clientId: string): Promise<void> {
  await publish(ROUTING_KEYS.orderCreated, {
    type: ROUTING_KEYS.orderCreated,
    orderId,
    restaurantId,
    clientId,
  });
}

export async function publishOrderAccepted(orderId: string, clientId: string): Promise<void> {
  await publish(ROUTING_KEYS.orderAccepted, {
    type: ROUTING_KEYS.orderAccepted,
    orderId,
    clientId,
  });
}

export async function publishOrderDeliveryAssigned(
  orderId: string,
  clientId: string,
  restaurantId: string
): Promise<void> {
  await publish(ROUTING_KEYS.orderDeliveryAssigned, {
    type: ROUTING_KEYS.orderDeliveryAssigned,
    orderId,
    clientId,
    restaurantId,
  });
}

export async function publishOrderInDelivery(orderId: string, clientId: string): Promise<void> {
  await publish(ROUTING_KEYS.orderInDelivery, {
    type: ROUTING_KEYS.orderInDelivery,
    orderId,
    clientId,
  });
}

export async function publishOrderDelivered(
  orderId: string,
  clientId: string,
  restaurantId: string
): Promise<void> {
  await publish(ROUTING_KEYS.orderDelivered, {
    type: ROUTING_KEYS.orderDelivered,
    orderId,
    clientId,
    restaurantId,
  });
}
