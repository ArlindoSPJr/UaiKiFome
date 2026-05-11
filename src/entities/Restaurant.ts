import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToOne,
  JoinColumn,
  OneToMany,
} from "typeorm";
import { User } from "./User";
import { MenuItem } from "./MenuItem";
import { Order } from "./Order";

@Entity("restaurants")
export class Restaurant {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  userId!: string;

  @OneToOne(() => User, (user) => user.restaurant)
  @JoinColumn({ name: "userId" })
  user!: User;

  @Column()
  name!: string;

  @Column({ nullable: true })
  description?: string;

  @Column()
  address!: string;

  @OneToMany(() => MenuItem, (item) => item.restaurant)
  menuItems!: MenuItem[];

  @OneToMany(() => Order, (order) => order.restaurant)
  orders!: Order[];
}
