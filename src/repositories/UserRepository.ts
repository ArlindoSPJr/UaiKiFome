import { AppDataSource } from "../config/database";
import { User } from "../entities/User";

export const UserRepository = AppDataSource.getRepository(User).extend({
  findByEmail(email: string) {
    return this.findOne({ where: { email } });
  },
});
