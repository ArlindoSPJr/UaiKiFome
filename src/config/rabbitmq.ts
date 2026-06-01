import amqp, { Channel } from "amqplib";

const EXCHANGE = "uaikifome";
const QUEUES = {
  restaurant: "restaurant_notifications",
  client: "client_notifications",
  delivery: "delivery_notifications",
};

export const ROUTING_KEYS = {
  orderCreated: "order.created",
  orderAccepted: "order.accepted",
  orderDeliveryAssigned: "order.delivery_assigned",
  orderInDelivery: "order.in_delivery",
  orderDelivered: "order.delivered",
};

let channel: Channel | null = null;

async function connect(retries = 5, delayMs = 3000): Promise<Channel> {
  const url = process.env.RABBITMQ_URL || "amqp://guest:guest@localhost:5672";
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const connection = await amqp.connect(url);
      return await connection.createChannel();
    } catch (err) {
      if (attempt === retries) throw err;
      console.log(`RabbitMQ não disponível, tentando novamente em ${delayMs / 1000}s... (${attempt}/${retries})`);
      await new Promise((res) => setTimeout(res, delayMs));
    }
  }
  throw new Error("Não foi possível conectar ao RabbitMQ");
}

export async function getRabbitMQChannel(): Promise<Channel> {
  if (channel) return channel;

  const ch = await connect();

  await ch.assertExchange(EXCHANGE, "topic", { durable: true });

  await ch.assertQueue(QUEUES.restaurant, { durable: true });
  await ch.assertQueue(QUEUES.client, { durable: true });
  await ch.assertQueue(QUEUES.delivery, { durable: true });

  await ch.bindQueue(QUEUES.restaurant, EXCHANGE, ROUTING_KEYS.orderCreated);
  await ch.bindQueue(QUEUES.client, EXCHANGE, ROUTING_KEYS.orderAccepted);
  await ch.bindQueue(QUEUES.delivery, EXCHANGE, ROUTING_KEYS.orderAccepted);

  // restaurante: também é notificado quando o entregador aceita e quando o pedido é entregue
  await ch.bindQueue(QUEUES.restaurant, EXCHANGE, ROUTING_KEYS.orderDeliveryAssigned);
  await ch.bindQueue(QUEUES.restaurant, EXCHANGE, ROUTING_KEYS.orderDelivered);
  // cliente: acompanha designação do entregador, saída para entrega e entrega final
  await ch.bindQueue(QUEUES.client, EXCHANGE, ROUTING_KEYS.orderDeliveryAssigned);
  await ch.bindQueue(QUEUES.client, EXCHANGE, ROUTING_KEYS.orderInDelivery);
  await ch.bindQueue(QUEUES.client, EXCHANGE, ROUTING_KEYS.orderDelivered);

  channel = ch;
  console.log("RabbitMQ conectado — exchange 'uaikifome' configurado");
  console.log(
    "[rabbitmq] Bindings registrados:\n" +
      `  • ${QUEUES.restaurant} ← [${ROUTING_KEYS.orderCreated}, ${ROUTING_KEYS.orderDeliveryAssigned}, ${ROUTING_KEYS.orderDelivered}]\n` +
      `  • ${QUEUES.client} ← [${ROUTING_KEYS.orderAccepted}, ${ROUTING_KEYS.orderDeliveryAssigned}, ${ROUTING_KEYS.orderInDelivery}, ${ROUTING_KEYS.orderDelivered}]\n` +
      `  • ${QUEUES.delivery} ← [${ROUTING_KEYS.orderAccepted}]`
  );
  return channel;
}

export { EXCHANGE, QUEUES };
