import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { User, UserRole } from "../entities/User";
import { UserRepository } from "../repositories/UserRepository";

interface RegisterDTO {
  name: string;
  email: string;
  password: string;
  role: UserRole;
}

export class AuthService {
  async register(data: RegisterDTO): Promise<Omit<User, "password">> {
    const existing = await UserRepository.findByEmail(data.email);
    if (existing) {
      throw { status: 400, message: "Email já cadastrado" };
    }

    if (!Object.values(UserRole).includes(data.role)) {
      throw { status: 400, message: `Role inválida. Use: ${Object.values(UserRole).join(", ")}` };
    }

    const hashed = await bcrypt.hash(data.password, 10);
    const user = UserRepository.create({ ...data, password: hashed });
    const saved = await UserRepository.save(user);

    const { password: _, ...userWithoutPassword } = saved;
    return userWithoutPassword;
  }

  async login(email: string, password: string): Promise<{ token: string; user: Omit<User, "password"> }> {
    const user = await UserRepository.findByEmail(email);
    if (!user) {
      throw { status: 401, message: "Credenciais inválidas" };
    }

    const valid = await bcrypt.compare(password, user.password);
    if (!valid) {
      throw { status: 401, message: "Credenciais inválidas" };
    }

    const secret = process.env.JWT_SECRET;
    if (!secret) throw { status: 500, message: "JWT_SECRET não configurado" };

    const token = jwt.sign({ sub: user.id, role: user.role }, secret, { expiresIn: "7d" });

    const { password: _, ...userWithoutPassword } = user;
    return { token, user: userWithoutPassword };
  }
}
