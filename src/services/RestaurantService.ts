import { AppDataSource } from "../config/database";
import { Restaurant } from "../entities/Restaurant";
import { MenuItem } from "../entities/MenuItem";
import { UserRole } from "../entities/User";
import { RestaurantRepository } from "../repositories/RestaurantRepository";

interface CreateMenuItemDTO {
  userId: string;
  role: UserRole;
  restaurantId: string;
  name: string;
  description?: string;
  price: number;
}

interface CreateRestaurantDTO {
  userId: string;
  role: UserRole;
  name: string;
  description?: string;
  address: string;
}

export class RestaurantService {
  async create(data: CreateRestaurantDTO): Promise<Restaurant> {
    if (data.role !== UserRole.RESTAURANT) {
      throw { status: 403, message: "Apenas usuários com role 'restaurant' podem criar restaurantes" };
    }

    const existing = await RestaurantRepository.findByUserId(data.userId);
    if (existing) {
      throw { status: 400, message: "Usuário já possui um restaurante cadastrado" };
    }

    const restaurant = RestaurantRepository.create(data);
    return RestaurantRepository.save(restaurant);
  }

  async findById(id: string): Promise<Restaurant> {
    const restaurant = await RestaurantRepository.findOne({ where: { id } });
    if (!restaurant) {
      throw { status: 404, message: "Restaurante não encontrado" };
    }
    return restaurant;
  }

  async getMenu(restaurantId: string): Promise<MenuItem[]> {
    const restaurant = await RestaurantRepository.findOne({ where: { id: restaurantId } });
    if (!restaurant) {
      throw { status: 404, message: "Restaurante não encontrado" };
    }
    return RestaurantRepository.findWithMenu(restaurantId);
  }

  async list(): Promise<Restaurant[]> {
    return RestaurantRepository.findAll();
  }

  async addMenuItem(data: CreateMenuItemDTO): Promise<MenuItem> {
    if (data.role !== UserRole.RESTAURANT) {
      throw { status: 403, message: "Apenas usuários com role 'restaurant' podem adicionar itens ao cardápio" };
    }

    const restaurant = await RestaurantRepository.findOne({ where: { id: data.restaurantId } });
    if (!restaurant) {
      throw { status: 404, message: "Restaurante não encontrado" };
    }

    if (restaurant.userId !== data.userId) {
      throw { status: 403, message: "Você não é o dono deste restaurante" };
    }

    const menuItemRepo = AppDataSource.getRepository(MenuItem);
    const item = menuItemRepo.create({
      restaurantId: data.restaurantId,
      name: data.name,
      description: data.description,
      price: data.price,
      available: true,
    });
    return menuItemRepo.save(item);
  }
}
