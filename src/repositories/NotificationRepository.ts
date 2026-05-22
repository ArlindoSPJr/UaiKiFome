import { AppDataSource } from "../config/database";
import { Notification } from "../entities/Notification";

export const NotificationRepository = AppDataSource.getRepository(Notification).extend({
  findByUser(userId: string) {
    return this.find({
      where: { userId },
      order: { createdAt: "DESC" },
    });
  },
});
