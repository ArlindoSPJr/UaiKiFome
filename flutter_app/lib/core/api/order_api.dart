import 'package:dio/dio.dart';
import '../models/order.dart';

class OrderApi {
  final Dio _dio;
  OrderApi(this._dio);

  Future<List<Order>> listOrders({String? clientId, String? restaurantId, String? status}) async {
    final res = await _dio.get('/orders', queryParameters: {
      if (clientId != null) 'clientId': clientId,
      if (restaurantId != null) 'restaurantId': restaurantId,
      if (status != null) 'status': status,
    });
    return (res.data as List).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> getOrder(String id) async {
    final res = await _dio.get('/orders/$id');
    return Order.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Order> createOrder({
    required String restaurantId,
    required String deliveryAddress,
    required List<Map<String, dynamic>> items,
  }) async {
    final res = await _dio.post('/orders', data: {
      'restaurantId': restaurantId,
      'deliveryAddress': deliveryAddress,
      'items': items,
    });
    return Order.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Order> updateStatus(String orderId, String status) async {
    final res = await _dio.patch('/orders/$orderId/status', data: {'status': status});
    return Order.fromJson(res.data as Map<String, dynamic>);
  }
}
