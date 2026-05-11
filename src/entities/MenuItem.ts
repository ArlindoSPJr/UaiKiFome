import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  OneToMany,
} from "typeorm";
import { Restaurant } from "./Restaurant";
import { OrderItem } from "./OrderItem";

@Entity("menu_items")
export class MenuItem {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  restaurantId!: string;

  @ManyToOne(() => Restaurant, (restaurant) => restaurant.menuItems)
  @JoinColumn({ name: "restaurantId" })
  restaurant!: Restaurant;

  @Column()
  name!: string;

  @Column({ nullable: true })
  description?: string;

  @Column({ type: "decimal", precision: 10, scale: 2 })
  price!: number;

  @Column({ default: true })
  available!: boolean;

  @OneToMany(() => OrderItem, (orderItem) => orderItem.menuItem)
  orderItems!: OrderItem[];
}
