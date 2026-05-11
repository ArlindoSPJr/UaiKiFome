import bcrypt from "bcryptjs";
import { User } from "../entities/User";
import { UserRepository } from "../repositories/UserRepository";

interface UpdateUserDTO {
  name?: string;
  email?: string;
  currentPassword?: string;
  newPassword?: string;
}

export class UserService {
  async update(userId: string, data: UpdateUserDTO): Promise<Omit<User, "password">> {
    const user = await UserRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw { status: 404, message: "Usuário não encontrado" };
    }

    if (data.email && data.email !== user.email) {
      const existing = await UserRepository.findByEmail(data.email);
      if (existing) {
        throw { status: 400, message: "Email já está em uso" };
      }
      user.email = data.email;
    }

    if (data.name) {
      user.name = data.name;
    }

    if (data.newPassword) {
      if (!data.currentPassword) {
        throw { status: 400, message: "currentPassword é obrigatório para alterar a senha" };
      }
      const valid = await bcrypt.compare(data.currentPassword, user.password);
      if (!valid) {
        throw { status: 401, message: "Senha atual incorreta" };
      }
      user.password = await bcrypt.hash(data.newPassword, 10);
    }

    const saved = await UserRepository.save(user);
    const { password: _, ...userWithoutPassword } = saved;
    return userWithoutPassword;
  }

  async remove(userId: string): Promise<void> {
    const user = await UserRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw { status: 404, message: "Usuário não encontrado" };
    }
    await UserRepository.remove(user);
  }
}
