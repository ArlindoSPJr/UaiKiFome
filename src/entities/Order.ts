import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  OneToMany,
  CreateDateColumn,
  UpdateDateColumn,
} from "typeorm";
import { User } from "./User";
import { Restaurant } from "./Restaurant";
import { OrderItem } from "./OrderItem";

export enum OrderStatus {
  CRIADO = "CRIADO",
  ACEITO = "ACEITO",
  ENTREGADOR_DESIGNADO = "ENTREGADOR_DESIGNADO",
  EM_ENTREGA = "EM_ENTREGA",
  ENTREGUE = "ENTREGUE",
}

const VALID_TRANSITIONS: Record<OrderStatus, OrderStatus | null> = {
  [OrderStatus.CRIADO]: OrderStatus.ACEITO,
  [OrderStatus.ACEITO]: OrderStatus.ENTREGADOR_DESIGNADO,
  [OrderStatus.ENTREGADOR_DESIGNADO]: OrderStatus.EM_ENTREGA,
  [OrderStatus.EM_ENTREGA]: OrderStatus.ENTREGUE,
  [OrderStatus.ENTREGUE]: null,
};

export function isValidTransition(from: OrderStatus, to: OrderStatus): boolean {
  return VALID_TRANSITIONS[from] === to;
}

@Entity("orders")
export class Order {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  clientId!: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: "clientId" })
  client!: User;

  @Column()
  restaurantId!: string;

  @ManyToOne(() => Restaurant, (restaurant) => restaurant.orders)
  @JoinColumn({ name: "restaurantId" })
  restaurant!: Restaurant;

  @Column({ nullable: true })
  deliveryPersonId?: string;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: "deliveryPersonId" })
  deliveryPerson?: User;

  @Column({ type: "enum", enum: OrderStatus, default: OrderStatus.CRIADO })
  status!: OrderStatus;

  @Column({ type: "decimal", precision: 10, scale: 2 })
  total!: number;

  @Column()
  deliveryAddress!: string;

  @OneToMany(() => OrderItem, (orderItem) => orderItem.order, { cascade: true })
  items!: OrderItem[];

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
