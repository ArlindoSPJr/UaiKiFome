import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/order_api.dart';
import '../../core/api/restaurant_api.dart';
import '../../core/models/order.dart';
import '../../core/models/restaurant.dart';
import '../../core/realtime/order_socket_service.dart';
import 'cart_item.dart';

class ClienteProvider extends ChangeNotifier {
  final String clientId;
  ClienteProvider({required this.clientId});

  final _orderApi = OrderApi(createDioClient());
  final _restaurantApi = RestaurantApi(createDioClient());
  final _socket = OrderSocketService();

  List<Restaurant> restaurants = [];
  List<Order> orders = [];
  List<CartItem> cartItems = [];
  String? cartRestaurantId;
  bool loadingRestaurants = false;
  bool loadingOrders = false;
  String? error;

  String get cartRestaurantName => restaurants
      .firstWhere(
        (r) => r.id == cartRestaurantId,
        orElse: () => const Restaurant(id: '', userId: '', name: '', address: ''),
      )
      .name;

  double get cartSubtotal =>
      cartItems.fold(0, (sum, i) => sum + i.price * i.quantity);

  int get cartCount => cartItems.fold(0, (sum, i) => sum + i.quantity);

  Future<void> fetchRestaurants() async {
    loadingRestaurants = true;
    error = null;
    notifyListeners();
    try {
      restaurants = await _restaurantApi.getRestaurants();
    } catch (e) {
      error = 'Erro ao carregar restaurantes';
    } finally {
      loadingRestaurants = false;
      notifyListeners();
    }
  }

  Future<void> fetchOrders() async {
    loadingOrders = true;
    notifyListeners();
    try {
      orders = await _orderApi.listOrders(clientId: clientId);
    } catch (_) {
      // silently fail
    } finally {
      loadingOrders = false;
      notifyListeners();
    }
  }

  void addToCart(
    String restaurantId,
    String menuItemId,
    String name,
    double price,
  ) {
    if (cartRestaurantId != null && cartRestaurantId != restaurantId) {
      cartItems.clear();
    }
    cartRestaurantId = restaurantId;
    final existing = cartItems.where((i) => i.menuItemId == menuItemId);
    if (existing.isNotEmpty) {
      existing.first.quantity++;
    } else {
      cartItems.add(
        CartItem(menuItemId: menuItemId, name: name, price: price, quantity: 1),
      );
    }
    notifyListeners();
  }

  void setCartQty(String menuItemId, int qty) {
    if (qty <= 0) {
      cartItems.removeWhere((i) => i.menuItemId == menuItemId);
    } else {
      final item = cartItems.firstWhere((i) => i.menuItemId == menuItemId);
      item.quantity = qty;
    }
    if (cartItems.isEmpty) cartRestaurantId = null;
    notifyListeners();
  }

  void clearCart() {
    cartItems.clear();
    cartRestaurantId = null;
    notifyListeners();
  }

  Future<Order?> placeOrder(String deliveryAddress) async {
    if (cartRestaurantId == null || cartItems.isEmpty) return null;
    try {
      final order = await _orderApi.createOrder(
        restaurantId: cartRestaurantId!,
        deliveryAddress: deliveryAddress,
        items: cartItems
            .map((i) => {'menuItemId': i.menuItemId, 'quantity': i.quantity})
            .toList(),
      );
      orders.insert(0, order);
      clearCart();
      return order;
    } catch (e) {
      return null;
    }
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      orders[idx] = orders[idx].copyWith(status: status, updatedAt: DateTime.now());
      notifyListeners();
    }
  }

  void initRealtime() {
    _socket.onStatus = applyStatusEvent;
    _socket.connect();
  }

  void applyStatusEvent(String orderId, String rawStatus) {
    final status = OrderStatus.fromName(rawStatus);
    if (status == null) return;
    updateOrderStatus(orderId, status);
  }

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }
}
