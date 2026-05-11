import { Request, Response, NextFunction } from "express";
import { UserService } from "../services/UserService";

const service = new UserService();

export class UserController {
  async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { name, email, currentPassword, newPassword } = req.body;
      if (!name && !email && !newPassword) {
        res.status(400).json({ error: "Informe ao menos um campo para atualizar: name, email ou newPassword" });
        return;
      }
      const user = await service.update(req.user!.id, { name, email, currentPassword, newPassword });
      res.json(user);
    } catch (err) {
      next(err);
    }
  }

  async remove(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await service.remove(req.user!.id);
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  }
}
