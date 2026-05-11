import { AppDataSource } from "../config/database";
import { Order, OrderStatus } from "../entities/Order";

export const OrderRepository = AppDataSource.getRepository(Order).extend({
  findWithItems(id: string) {
    return this.findOne({
      where: { id },
      relations: ["items", "items.menuItem"],
    });
  },

  findByFilters(filters: {
    restaurantId?: string;
    clientId?: string;
    status?: OrderStatus;
  }) {
    return this.find({
      where: {
        ...(filters.restaurantId && { restaurantId: filters.restaurantId }),
        ...(filters.clientId && { clientId: filters.clientId }),
        ...(filters.status && { status: filters.status }),
      },
      relations: ["items"],
      order: { createdAt: "DESC" },
    });
  },
});
