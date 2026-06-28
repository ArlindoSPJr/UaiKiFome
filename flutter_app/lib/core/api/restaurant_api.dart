import 'package:dio/dio.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';

class RestaurantApi {
  final Dio _dio;
  RestaurantApi(this._dio);

  Future<List<Restaurant>> getRestaurants() async {
    final res = await _dio.get('/restaurants');
    return (res.data as List).map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Restaurant?> getMyRestaurant() async {
    try {
      final res = await _dio.get('/restaurants/mine');
      return Restaurant.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
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
    required int quantity,
  }) async {
    final res = await _dio.post('/restaurants/$restaurantId/menu', data: {
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      'quantity': quantity,
    });
    return MenuItem.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MenuItem> toggleMenuItemAvailability({
    required String restaurantId,
    required String menuItemId,
    required bool available,
  }) async {
    final res = await _dio.patch(
      '/restaurants/$restaurantId/menu/$menuItemId',
      data: {'available': available},
    );
    return MenuItem.fromJson(res.data as Map<String, dynamic>);
  }
}
