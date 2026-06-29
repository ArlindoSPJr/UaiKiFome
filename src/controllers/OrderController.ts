import { Request, Response, NextFunction } from "express";
import { OrderService } from "../services/OrderService";
import { OrderStatus } from "../entities/Order";
import { UserRole } from "../entities/User";

const service = new OrderService();

export class OrderController {
  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { restaurantId, deliveryAddress, items } = req.body;
      if (!restaurantId || !deliveryAddress || !items) {
        res.status(400).json({ error: "restaurantId, deliveryAddress e items são obrigatórios" });
        return;
      }
      const order = await service.create({ clientId: req.user!.id, role: req.user!.role, restaurantId, deliveryAddress, items });
      res.status(201).json(order);
    } catch (err) {
      next(err);
    }
  }

  async findById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const order = await service.findById(req.params.id);
      res.json(order);
    } catch (err) {
      next(err);
    }
  }

  async list(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { restaurantId, clientId, deliveryPersonId, status } = req.query;
      // Cliente só vê os próprios pedidos: id vem do token, não da query.
      const effectiveClientId =
        req.user!.role === UserRole.CLIENT ? req.user!.id : (clientId as string | undefined);
      // Entregador não vê os pedidos que já recusou.
      const excludeRejectedBy =
        req.user!.role === UserRole.DELIVERY ? req.user!.id : undefined;
      const orders = await service.list({
        restaurantId: restaurantId as string | undefined,
        clientId: effectiveClientId,
        deliveryPersonId: deliveryPersonId as string | undefined,
        status: status as OrderStatus | undefined,
        excludeRejectedBy,
      });
      res.json(orders);
    } catch (err) {
      next(err);
    }
  }

  async reject(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await service.rejectOrder(req.params.id, req.user!.id, req.user!.role);
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  }

  async updateStatus(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { status } = req.body;
      if (!status) {
        res.status(400).json({ error: "status é obrigatório" });
        return;
      }
      const deliveryPersonId = status === OrderStatus.ENTREGADOR_DESIGNADO ? req.user!.id : undefined;
      const order = await service.updateStatus(req.params.id, status as OrderStatus, req.user!.role, deliveryPersonId);
      res.json(order);
    } catch (err) {
      next(err);
    }
  }
}
