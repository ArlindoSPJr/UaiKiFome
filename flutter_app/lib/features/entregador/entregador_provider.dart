import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/order_api.dart';
import '../../core/api/restaurant_api.dart';
import '../../core/models/order.dart';
import '../../core/models/restaurant.dart';
import '../../core/realtime/order_socket_service.dart';

class EntregadorProvider extends ChangeNotifier {
  final String userId;
  EntregadorProvider({required this.userId});

  final _orderApi = OrderApi(createDioClient());
  final _restaurantApi = RestaurantApi(createDioClient());
  final _socket = OrderSocketService();

  // Pedidos aceitos pelo restaurante e ainda sem entregador.
  List<Order> availableOrders = [];
  // Pedidos que este entregador está realizando (EM_ENTREGA / ENTREGADOR_DESIGNADO).
  List<Order> myOrders = [];
  // Pedidos já entregues por este entregador.
  List<Order> completedOrders = [];
  // Pedidos recusados localmente (não há estado de rejeição no backend).
  final Set<String> rejectedIds = {};
  // Mapa restaurantId -> restaurante, para exibir o ponto de retirada.
  Map<String, Restaurant> restaurantsById = {};

  bool loadingAvailable = false;
  bool loadingMine = false;
  String? error;

  Future<void> init() async {
    await Future.wait([fetchRestaurants(), fetchAvailableOrders(), fetchMyOrders()]);
    _socket.onStatus = applyStatusEvent;
    _socket.connect();
  }

  Restaurant? restaurantOf(Order order) => restaurantsById[order.restaurantId];

  Future<void> fetchRestaurants() async {
    try {
      final list = await _restaurantApi.getRestaurants();
      restaurantsById = {for (final r in list) r.id: r};
      notifyListeners();
    } catch (_) {
      // exibição do restaurante é opcional; ignora falha
    }
  }

  Future<void> fetchAvailableOrders() async {
    loadingAvailable = true;
    error = null;
    notifyListeners();
    try {
      final list = await _orderApi.listOrders(status: OrderStatus.ACEITO.name);
      availableOrders = list.where((o) => !rejectedIds.contains(o.id)).toList();
    } catch (_) {
      error = 'Erro ao carregar pedidos disponíveis';
    } finally {
      loadingAvailable = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyOrders() async {
    loadingMine = true;
    notifyListeners();
    try {
      final list = await _orderApi.listOrders(deliveryPersonId: userId);
      myOrders = list
          .where((o) =>
              o.status == OrderStatus.EM_ENTREGA ||
              o.status == OrderStatus.ENTREGADOR_DESIGNADO)
          .toList();
      completedOrders =
          list.where((o) => o.status == OrderStatus.ENTREGUE).toList();
    } catch (_) {
      error = 'Erro ao carregar minhas entregas';
    } finally {
      loadingMine = false;
      notifyListeners();
    }
  }

  /// Aceitar = iniciar entrega: reivindica o pedido (ENTREGADOR_DESIGNADO) e em
  /// seguida dispara o evento de entrega (EM_ENTREGA).
  Future<bool> acceptOrder(String orderId) async {
    try {
      await _orderApi.updateStatus(orderId, OrderStatus.ENTREGADOR_DESIGNADO.name);
      final updated =
          await _orderApi.updateStatus(orderId, OrderStatus.EM_ENTREGA.name);
      availableOrders.removeWhere((o) => o.id == orderId);
      myOrders.removeWhere((o) => o.id == orderId);
      myOrders.insert(0, updated);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> completeOrder(String orderId) async {
    try {
      final updated = await _orderApi.updateStatus(orderId, OrderStatus.ENTREGUE.name);
      myOrders.removeWhere((o) => o.id == orderId);
      completedOrders.insert(0, updated);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Recusa local: o backend não tem estado de rejeição, então apenas escondemos
  /// o pedido para este entregador.
  void rejectOrder(String orderId) {
    rejectedIds.add(orderId);
    availableOrders.removeWhere((o) => o.id == orderId);
    notifyListeners();
  }

  Future<void> applyStatusEvent(String orderId, String rawStatus) async {
    final status = OrderStatus.fromName(rawStatus);
    if (status == null) return;

    // Atualiza um pedido que já está entre os meus.
    final mineIdx = myOrders.indexWhere((o) => o.id == orderId);
    if (mineIdx != -1) {
      if (status == OrderStatus.ENTREGUE) {
        final done = myOrders.removeAt(mineIdx).copyWith(status: status, updatedAt: DateTime.now());
        completedOrders.insert(0, done);
      } else {
        myOrders[mineIdx] =
            myOrders[mineIdx].copyWith(status: status, updatedAt: DateTime.now());
      }
      notifyListeners();
      return;
    }

    if (status == OrderStatus.ACEITO) {
      // Novo pedido disponível para entrega.
      if (rejectedIds.contains(orderId)) return;
      if (availableOrders.any((o) => o.id == orderId)) return;
      try {
        final order = await _orderApi.getOrder(orderId);
        if (order.status == OrderStatus.ACEITO &&
            !availableOrders.any((o) => o.id == orderId)) {
          availableOrders.insert(0, order);
          notifyListeners();
        }
      } catch (_) {
        // ignora falha ao buscar o pedido
      }
    } else {
      // Saiu da lista de disponíveis (outro entregador pegou).
      final before = availableOrders.length;
      availableOrders.removeWhere((o) => o.id == orderId);
      if (availableOrders.length != before) notifyListeners();
    }
  }

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }
}
