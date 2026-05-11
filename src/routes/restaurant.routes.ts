import { Router } from "express";
import { RestaurantController } from "../controllers/RestaurantController";
import { authenticate } from "../middlewares/authenticate";

const router = Router();
const controller = new RestaurantController();

router.use(authenticate);
router.post("/", (req, res, next) => controller.create(req, res, next));
router.get("/:id/menu", (req, res, next) => controller.getMenu(req, res, next));
router.post("/:id/menu", (req, res, next) => controller.addMenuItem(req, res, next));

export default router;
