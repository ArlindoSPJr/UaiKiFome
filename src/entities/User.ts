import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  OneToOne,
} from "typeorm";
import { Restaurant } from "./Restaurant";

export enum UserRole {
  RESTAURANT = "restaurant",
  CLIENT = "client",
  DELIVERY = "delivery",
}

@Entity("users")
export class User {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  name!: string;

  @Column({ unique: true })
  email!: string;

  @Column()
  password!: string;

  @Column({ type: "enum", enum: UserRole })
  role!: UserRole;

  @CreateDateColumn()
  createdAt!: Date;

  @OneToOne(() => Restaurant, (restaurant) => restaurant.user)
  restaurant?: Restaurant;
}
