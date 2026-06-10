import 'package:dio/dio.dart';

class AuthApi {
  final Dio _dio;
  AuthApi(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    final res = await _dio.post('/auth/register', data: {
      'name': name, 'email': email, 'password': password, 'role': role,
    });
    return res.data as Map<String, dynamic>;
  }
}
