import { getRabbitMQChannel, QUEUES } from "../../config/rabbitmq";
import { NotificationService } from "../../services/NotificationService";
import { UserRepository } from "../../repositories/UserRepository";
import { RestaurantRepository } from "../../repositories/RestaurantRepository";
import { UserRole } from "../../entities/User";

const notificationService = new NotificationService();

export async function startConsumers(): Promise<void> {
  const channel = await getRabbitMQChannel();

  channel.consume(QUEUES.restaurant, async (msg) => {
    if (!msg) return;
    try {
      const { orderId, restaurantId } = JSON.parse(msg.content.toString());
      const restaurant = await RestaurantRepository.findOne({ where: { id: restaurantId } });
      if (!restaurant) throw new Error(`Restaurante não encontrado: ${restaurantId}`);
      await notificationService.create({
        userId: restaurant.userId,
        type: "order.created",
        message: "Novo pedido recebido",
        orderId,
      });
      channel.ack(msg);
      console.log(`[consumer] order.created processado — pedido ${orderId}`);
    } catch (err) {
      console.error("[consumer] Erro ao processar order.created:", err);
      channel.nack(msg, false, false);
    }
  });

  channel.consume(QUEUES.client, async (msg) => {
    if (!msg) return;
    const { orderId, clientId } = JSON.parse(msg.content.toString());
    await notificationService.create({
      userId: clientId,
      type: "order.accepted",
      message: "Seu pedido foi aceito pelo restaurante",
      orderId,
    });
    channel.ack(msg);
    console.log(`[consumer] order.accepted (client) processado — pedido ${orderId}`);
  });

  channel.consume(QUEUES.delivery, async (msg) => {
    if (!msg) return;
    const { orderId } = JSON.parse(msg.content.toString());
    const deliveryUsers = await UserRepository.find({ where: { role: UserRole.DELIVERY } });
    await Promise.all(
      deliveryUsers.map((user) =>
        notificationService.create({
          userId: user.id,
          type: "order.accepted",
          message: "Novo pedido disponível para entrega",
          orderId,
        })
      )
    );
    channel.ack(msg);
    console.log(`[consumer] order.accepted (delivery) processado — pedido ${orderId}`);
  });

  console.log("Workers RabbitMQ iniciados — aguardando mensagens");
}
