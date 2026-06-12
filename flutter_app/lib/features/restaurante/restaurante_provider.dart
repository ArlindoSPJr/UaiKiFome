import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/order_api.dart';
import '../../core/api/restaurant_api.dart';
import '../../core/models/menu_item.dart';
import '../../core/models/order.dart';
import '../../core/models/restaurant.dart';

class RestauranteProvider extends ChangeNotifier {
  final String userId;
  RestauranteProvider({required this.userId});

  final _restaurantApi = RestaurantApi(createDioClient());
  final _orderApi = OrderApi(createDioClient());

  Restaurant? myRestaurant;
  List<MenuItem> menuItems = [];
  List<Order> orders = [];
  bool loadingRestaurant = false;
  bool loadingOrders = false;
  bool loadingMenu = false;
  String? error;

  Future<void> init() async {
    await fetchMyRestaurant();
    if (myRestaurant != null) {
      await Future.wait([fetchOrders(), fetchMenu()]);
    }
  }

  Future<void> fetchMyRestaurant() async {
    loadingRestaurant = true;
    error = null;
    notifyListeners();
    try {
      myRestaurant = await _restaurantApi.getMyRestaurant();
    } catch (_) {
      error = 'Erro ao carregar restaurante';
    } finally {
      loadingRestaurant = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrders() async {
    if (myRestaurant == null) return;
    loadingOrders = true;
    notifyListeners();
    try {
      orders = await _orderApi.listOrders(restaurantId: myRestaurant!.id);
    } catch (_) {
    } finally {
      loadingOrders = false;
      notifyListeners();
    }
  }

  Future<void> fetchMenu() async {
    if (myRestaurant == null) return;
    loadingMenu = true;
    notifyListeners();
    try {
      menuItems = await _restaurantApi.getMenu(myRestaurant!.id);
    } catch (_) {
    } finally {
      loadingMenu = false;
      notifyListeners();
    }
  }

  Future<void> acceptOrder(String orderId) async {
    try {
      final updated = await _orderApi.updateStatus(orderId, OrderStatus.ACEITO.name);
      final idx = orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) orders[idx] = updated;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> addMenuItem({
    required String name,
    String? description,
    required double price,
  }) async {
    if (myRestaurant == null) return false;
    try {
      final item = await _restaurantApi.addMenuItem(
        restaurantId: myRestaurant!.id,
        name: name,
        description: description,
        price: price,
      );
      menuItems = [...menuItems, item];
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleAvailability(String menuItemId, bool available) async {
    if (myRestaurant == null) return;
    try {
      final updated = await _restaurantApi.toggleMenuItemAvailability(
        restaurantId: myRestaurant!.id,
        menuItemId: menuItemId,
        available: available,
      );
      menuItems = menuItems.map((i) => i.id == menuItemId ? updated : i).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createMyRestaurant({
    required String name,
    String? description,
    required String address,
  }) async {
    try {
      myRestaurant = await _restaurantApi.createRestaurant(
        name: name,
        description: description,
        address: address,
      );
      notifyListeners();
      await Future.wait([fetchOrders(), fetchMenu()]);
      return true;
    } catch (_) {
      return false;
    }
  }
}
