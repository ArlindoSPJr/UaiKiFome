import { Request, Response, NextFunction } from "express";
import { NotificationService } from "../services/NotificationService";

const service = new NotificationService();

export class NotificationController {
  async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const notifications = await service.findByUser(req.user!.id);
      res.json(notifications);
    } catch (err) {
      next(err);
    }
  }
}
