import { In, Not } from "typeorm";
import { AppDataSource } from "../config/database";
import { Order, OrderStatus } from "../entities/Order";

export const OrderRepository = AppDataSource.getRepository(Order).extend({
  findWithItems(id: string) {
    return this.findOne({
      where: { id },
      relations: ["items", "items.menuItem", "restaurant", "client"],
    });
  },

  findByFilters(filters: {
    restaurantId?: string;
    clientId?: string;
    deliveryPersonId?: string;
    status?: OrderStatus;
    excludeIds?: string[];
  }) {
    return this.find({
      where: {
        ...(filters.restaurantId && { restaurantId: filters.restaurantId }),
        ...(filters.clientId && { clientId: filters.clientId }),
        ...(filters.deliveryPersonId && { deliveryPersonId: filters.deliveryPersonId }),
        ...(filters.status && { status: filters.status }),
        ...(filters.excludeIds && filters.excludeIds.length > 0 && { id: Not(In(filters.excludeIds)) }),
      },
      relations: ["items", "items.menuItem", "restaurant", "client"],
      order: { createdAt: "DESC" },
    });
  },
});
