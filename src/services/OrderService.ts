import { AppDataSource } from "../config/database";
import { Order, OrderStatus, isValidTransition } from "../entities/Order";
import { MenuItem } from "../entities/MenuItem";
import { OrderItem } from "../entities/OrderItem";
import { UserRole } from "../entities/User";
import { OrderRepository } from "../repositories/OrderRepository";
import { RestaurantRepository } from "../repositories/RestaurantRepository";
import {
  publishOrderCreated,
  publishOrderAccepted,
  publishOrderDeliveryAssigned,
  publishOrderInDelivery,
  publishOrderDelivered,
} from "../events/publishers/OrderPublisher";
import { notifyUser } from "../websocket/wsServer";

interface OrderItemInput {
  menuItemId: string;
  quantity: number;
}

interface CreateOrderDTO {
  clientId: string;
  role: UserRole;
  restaurantId: string;
  deliveryAddress: string;
  items: OrderItemInput[];
}

export class OrderService {
  async create(data: CreateOrderDTO): Promise<Order> {
    if (data.role !== UserRole.CLIENT) {
      throw { status: 403, message: "Apenas usuários com role 'client' podem criar pedidos" };
    }

    if (!data.items || data.items.length === 0) {
      throw { status: 400, message: "O pedido deve ter ao menos um item" };
    }

    const menuItemRepo = AppDataSource.getRepository(MenuItem);
    const orderItems: OrderItem[] = [];
    let total = 0;

    for (const input of data.items) {
      const menuItem = await menuItemRepo.findOne({
        where: { id: input.menuItemId, restaurantId: data.restaurantId, available: true },
      });
      if (!menuItem) {
        throw { status: 400, message: `Item ${input.menuItemId} não encontrado ou indisponível` };
      }
      if (input.quantity <= 0) {
        throw { status: 400, message: "Quantidade deve ser maior que zero" };
      }

      const orderItem = new OrderItem();
      orderItem.menuItemId = menuItem.id;
      orderItem.quantity = input.quantity;
      orderItem.unitPrice = Number(menuItem.price);
      orderItems.push(orderItem);
      total += orderItem.unitPrice * input.quantity;
    }

    const order = OrderRepository.create({
      clientId: data.clientId,
      restaurantId: data.restaurantId,
      deliveryAddress: data.deliveryAddress,
      status: OrderStatus.CRIADO,
      total: Math.round(total * 100) / 100,
      items: orderItems,
    });

    const saved = await OrderRepository.save(order);

    publishOrderCreated(saved.id, saved.restaurantId, saved.clientId).catch((err) =>
      console.error("[publisher] Erro ao publicar order.created:", err)
    );

    return saved;
  }

  async findById(id: string): Promise<Order> {
    const order = await OrderRepository.findWithItems(id);
    if (!order) {
      throw { status: 404, message: "Pedido não encontrado" };
    }
    return order;
  }

  async list(filters: { restaurantId?: string; clientId?: string; status?: OrderStatus }): Promise<Order[]> {
    return OrderRepository.findByFilters(filters);
  }

  async updateStatus(id: string, newStatus: OrderStatus, role: UserRole, deliveryPersonId?: string): Promise<Order> {
    const order = await OrderRepository.findOne({ where: { id } });
    if (!order) {
      throw { status: 404, message: "Pedido não encontrado" };
    }

    if (!isValidTransition(order.status, newStatus)) {
      throw {
        status: 422,
        message: `Transição inválida: ${order.status} → ${newStatus}`,
      };
    }

    const restaurantStatuses = [OrderStatus.ACEITO];
    const deliveryStatuses = [OrderStatus.ENTREGADOR_DESIGNADO, OrderStatus.EM_ENTREGA, OrderStatus.ENTREGUE];

    if (restaurantStatuses.includes(newStatus) && role !== UserRole.RESTAURANT) {
      throw { status: 403, message: "Apenas usuários com role 'restaurant' podem executar esta transição" };
    }
    if (deliveryStatuses.includes(newStatus) && role !== UserRole.DELIVERY) {
      throw { status: 403, message: "Apenas usuários com role 'delivery' podem executar esta transição" };
    }

    if (newStatus === OrderStatus.ENTREGADOR_DESIGNADO) {
      if (!deliveryPersonId) {
        throw { status: 400, message: "deliveryPersonId é obrigatório para esta transição" };
      }
      order.deliveryPersonId = deliveryPersonId;
    }

    order.status = newStatus;
    const saved = await OrderRepository.save(order);

    const logErr = (event: string) => (err: unknown) =>
      console.error(`[producer] Erro ao publicar ${event} (pedido ${saved.id}):`, err);

    if (newStatus === OrderStatus.ACEITO) {
      publishOrderAccepted(saved.id, saved.clientId).catch(logErr("order.accepted"));
    } else if (newStatus === OrderStatus.ENTREGADOR_DESIGNADO) {
      publishOrderDeliveryAssigned(saved.id, saved.clientId, saved.restaurantId).catch(
        logErr("order.delivery_assigned")
      );
    } else if (newStatus === OrderStatus.EM_ENTREGA) {
      publishOrderInDelivery(saved.id, saved.clientId).catch(logErr("order.in_delivery"));
    } else if (newStatus === OrderStatus.ENTREGUE) {
      publishOrderDelivered(saved.id, saved.clientId, saved.restaurantId).catch(logErr("order.delivered"));
    }

    const wsPayload = {
      event: "order_status_updated",
      orderId: saved.id,
      status: saved.status,
      updatedAt: saved.updatedAt,
    };

    notifyUser(saved.clientId, wsPayload);

    RestaurantRepository.findOne({ where: { id: saved.restaurantId } })
      .then((restaurant) => {
        if (restaurant && restaurant.userId) {
          notifyUser(restaurant.userId, wsPayload);
        }
      })
      .catch((err) => {
        console.error(`[wsServer] Erro ao buscar restaurante para notificação WS (pedido ${saved.id}):`, err);
      });

    return saved;
  }
}
