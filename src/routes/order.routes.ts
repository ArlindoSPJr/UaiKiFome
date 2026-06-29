import { Router } from "express";
import { OrderController } from "../controllers/OrderController";
import { authenticate } from "../middlewares/authenticate";

const router = Router();
const controller = new OrderController();

router.use(authenticate);
router.post("/", (req, res, next) => controller.create(req, res, next));
router.get("/", (req, res, next) => controller.list(req, res, next));
router.get("/:id", (req, res, next) => controller.findById(req, res, next));
router.patch("/:id/status", (req, res, next) => controller.updateStatus(req, res, next));
router.post("/:id/reject", (req, res, next) => controller.reject(req, res, next));

export default router;
