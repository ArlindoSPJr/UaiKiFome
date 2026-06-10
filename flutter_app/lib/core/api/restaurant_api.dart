import 'package:dio/dio.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';

class RestaurantApi {
  final Dio _dio;
  RestaurantApi(this._dio);

  Future<List<Restaurant>> getRestaurants() async {
    final res = await _dio.get('/restaurants');
    return (res.data as List).map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Restaurant> createRestaurant({required String name, String? description, required String address}) async {
    final res = await _dio.post('/restaurants', data: {
      'name': name,
      if (description != null) 'description': description,
      'address': address,
    });
    return Restaurant.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<MenuItem>> getMenu(String restaurantId) async {
    final res = await _dio.get('/restaurants/$restaurantId/menu');
    return (res.data as List).map((e) => MenuItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MenuItem> addMenuItem({
    required String restaurantId,
    required String name,
    String? description,
    required double price,
  }) async {
    final res = await _dio.post('/restaurants/$restaurantId/menu', data: {
      'name': name,
      if (description != null) 'description': description,
      'price': price,
    });
    return MenuItem.fromJson(res.data as Map<String, dynamic>);
  }
}
