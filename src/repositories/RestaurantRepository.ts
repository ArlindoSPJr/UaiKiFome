import { AppDataSource } from "../config/database";
import { Restaurant } from "../entities/Restaurant";
import { MenuItem } from "../entities/MenuItem";

export const RestaurantRepository = AppDataSource.getRepository(Restaurant).extend({
  findByUserId(userId: string) {
    return this.findOne({ where: { userId } });
  },

  findWithMenu(id: string) {
    return AppDataSource.getRepository(MenuItem).find({
      where: { restaurantId: id, available: true },
    });
  },
});
