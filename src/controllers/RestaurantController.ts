import { Request, Response, NextFunction } from "express";
import { RestaurantService } from "../services/RestaurantService";

const service = new RestaurantService();

export class RestaurantController {
  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { name, description, address } = req.body;
      if (!name || !address) {
        res.status(400).json({ error: "name e address são obrigatórios" });
        return;
      }
      const restaurant = await service.create({ userId: req.user!.id, role: req.user!.role, name, description, address });
      res.status(201).json(restaurant);
    } catch (err) {
      next(err);
    }
  }

  async getMenu(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const menu = await service.getMenu(id);
      res.json(menu);
    } catch (err) {
      next(err);
    }
  }

  async addMenuItem(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { name, description, price } = req.body;
      if (!name || price === undefined) {
        res.status(400).json({ error: "name e price são obrigatórios" });
        return;
      }
      if (typeof price !== "number" || price <= 0) {
        res.status(400).json({ error: "price deve ser um número maior que zero" });
        return;
      }
      const item = await service.addMenuItem({
        userId: req.user!.id,
        role: req.user!.role,
        restaurantId: req.params.id,
        name,
        description,
        price,
      });
      res.status(201).json(item);
    } catch (err) {
      next(err);
    }
  }
}
