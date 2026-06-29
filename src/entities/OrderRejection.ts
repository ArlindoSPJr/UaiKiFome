import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from "typeorm";
import { Order } from "./Order";
import { User } from "./User";

// Registra que um entregador recusou um pedido. A recusa é por entregador:
// o pedido continua disponível para os demais. Unicidade evita duplicatas.
@Entity("order_rejections")
@Index(["orderId", "deliveryPersonId"], { unique: true })
export class OrderRejection {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column()
  orderId!: string;

  @ManyToOne(() => Order)
  @JoinColumn({ name: "orderId" })
  order!: Order;

  @Column()
  deliveryPersonId!: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: "deliveryPersonId" })
  deliveryPerson!: User;

  @CreateDateColumn()
  createdAt!: Date;
}
