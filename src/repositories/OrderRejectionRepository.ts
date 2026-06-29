import { AppDataSource } from "../config/database";
import { OrderRejection } from "../entities/OrderRejection";

export const OrderRejectionRepository = AppDataSource.getRepository(OrderRejection).extend({
  // IDs dos pedidos recusados por um entregador.
  async findOrderIdsByDeliveryPerson(deliveryPersonId: string): Promise<string[]> {
    const rejections = await this.find({ where: { deliveryPersonId } });
    return rejections.map((r) => r.orderId);
  },
});
