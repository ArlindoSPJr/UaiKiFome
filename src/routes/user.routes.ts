import { Router } from "express";
import { UserController } from "../controllers/UserController";
import { authenticate } from "../middlewares/authenticate";

const router = Router();
const controller = new UserController();

router.use(authenticate);
router.patch("/me", (req, res, next) => controller.update(req, res, next));
router.delete("/me", (req, res, next) => controller.remove(req, res, next));

export default router;
