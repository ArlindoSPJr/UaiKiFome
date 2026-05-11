import "reflect-metadata";
import { DataSource } from "typeorm";
import dotenv from "dotenv";
import { User } from "../entities/User";
import { Restaurant } from "../entities/Restaurant";
import { MenuItem } from "../entities/MenuItem";
import { Order } from "../entities/Order";
import { OrderItem } from "../entities/OrderItem";

dotenv.config();

export const AppDataSource = new DataSource({
  type: "postgres",
  host: process.env.DB_HOST || "localhost",
  port: Number(process.env.DB_PORT) || 5432,
  username: process.env.DB_USERNAME || "uaikifome",
  password: process.env.DB_PASSWORD || "uaikifome123",
  database: process.env.DB_DATABASE || "uaikifome",
  synchronize: true,
  logging: false,
  entities: [User, Restaurant, MenuItem, Order, OrderItem],
  migrations: [],
});
