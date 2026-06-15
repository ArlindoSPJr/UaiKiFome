import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/api/auth_api.dart';
import '../../core/models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null && _token != null;

  final _api = AuthApi(createDioClient());

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userJson = prefs.getString('auth_user');
    if (token != null && userJson != null) {
      try {
        _token = token;
        _user = User.fromJson(json.decode(userJson) as Map<String, dynamic>);
        notifyListeners();
      } catch (_) {
        await logout();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.login(email, password);
      await _saveSession(data);
      return true;
    } catch (e) {
      _error = _extractError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(
      String name, String email, String password, String role) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.register(name, email, password, role);
      return await login(email, password);
    } catch (e) {
      _error = _extractError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    _user = null;
    _token = null;
    notifyListeners();
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    _token = data['token'] as String;
    _user = User.fromJson(data['user'] as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setString('auth_user', json.encode(_user!.toJson()));
    notifyListeners();
  }

  String _extractError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] is String) {
        return data['error'] as String;
      }
      return 'Erro ao conectar. Tente novamente.';
    }
    if (e is Exception) return e.toString().replaceFirst('Exception: ', '');
    return 'Erro ao conectar. Tente novamente.';
  }
}
