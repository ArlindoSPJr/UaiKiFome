import { Request, Response, NextFunction } from "express";
import { AuthService } from "../services/AuthService";
import { UserRole } from "../entities/User";

const service = new AuthService();

export class AuthController {
  async register(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { name, email, password, role } = req.body;
      if (!name || !email || !password || !role) {
        res.status(400).json({ error: "name, email, password e role são obrigatórios" });
        return;
      }
      if (!Object.values(UserRole).includes(role)) {
        res.status(400).json({ error: `Role inválida. Use: ${Object.values(UserRole).join(", ")}` });
        return;
      }
      const user = await service.register({ name, email, password, role });
      res.status(201).json(user);
    } catch (err) {
      next(err);
    }
  }

  async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, password } = req.body;
      if (!email || !password) {
        res.status(400).json({ error: "email e password são obrigatórios" });
        return;
      }
      const result = await service.login(email, password);
      res.json(result);
    } catch (err) {
      next(err);
    }
  }
}
