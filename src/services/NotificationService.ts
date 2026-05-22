import { NotificationRepository } from "../repositories/NotificationRepository";
import { Notification } from "../entities/Notification";

interface CreateNotificationDTO {
  userId: string;
  type: string;
  message: string;
  orderId: string;
}

export class NotificationService {
  async create(data: CreateNotificationDTO): Promise<Notification> {
    const notification = NotificationRepository.create(data);
    return NotificationRepository.save(notification);
  }

  async findByUser(userId: string): Promise<Notification[]> {
    return NotificationRepository.findByUser(userId);
  }
}
