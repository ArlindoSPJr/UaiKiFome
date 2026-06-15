import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from "typeorm";
import { Order } from "./Order";
import { MenuItem } from "./MenuItem";
import { decimalTransformer } from "./decimalTransformer";

@Entity("order_items")
export class OrderItem {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  orderId!: string;

  @ManyToOne(() => Order, (order) => order.items)
  @JoinColumn({ name: "orderId" })
  order!: Order;

  @Column()
  menuItemId!: string;

  @ManyToOne(() => MenuItem, (menuItem) => menuItem.orderItems)
  @JoinColumn({ name: "menuItemId" })
  menuItem!: MenuItem;

  @Column({ type: "int" })
  quantity!: number;

  @Column({ type: "decimal", precision: 10, scale: 2, transformer: decimalTransformer })
  unitPrice!: number;
}
