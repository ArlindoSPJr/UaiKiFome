import { Router } from "express";
import { NotificationController } from "../controllers/NotificationController";
import { authenticate } from "../middlewares/authenticate";

const router = Router();
const controller = new NotificationController();

router.use(authenticate);
router.get("/", (req, res, next) => controller.list(req, res, next));

export default router;
