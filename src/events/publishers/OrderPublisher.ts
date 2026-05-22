import { getRabbitMQChannel, EXCHANGE, ROUTING_KEYS } from "../../config/rabbitmq";

export async function publishOrderCreated(orderId: string, restaurantId: string, clientId: string): Promise<void> {
  const channel = await getRabbitMQChannel();
  const payload = JSON.stringify({ orderId, restaurantId, clientId });
  channel.publish(EXCHANGE, ROUTING_KEYS.orderCreated, Buffer.from(payload), { persistent: true });
}

export async function publishOrderAccepted(orderId: string, clientId: string): Promise<void> {
  const channel = await getRabbitMQChannel();
  const payload = JSON.stringify({ orderId, clientId });
  channel.publish(EXCHANGE, ROUTING_KEYS.orderAccepted, Buffer.from(payload), { persistent: true });
}
