import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';

String get _wsBaseUrl {
  if (kIsWeb) return 'ws://localhost:3000';
  if (Platform.isAndroid) return 'ws://10.0.2.2:3000';
  return 'ws://localhost:3000';
}

class OrderSocketService {
  void Function(String orderId, String status)? onStatus;

  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  bool _disposed = false;

  Future<void> connect() async {
    if (_disposed) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    try {
      final channel =
          IOWebSocketChannel.connect(Uri.parse('$_wsBaseUrl?token=$token'));
      _channel = channel;
      _sub = channel.stream.listen(
        _onMessage,
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      if (data['event'] != 'order_status_updated') return;
      final orderId = data['orderId'] as String?;
      final status = data['status'] as String?;
      if (orderId != null && status != null) {
        onStatus?.call(orderId, status);
      }
    } catch (_) {
      // payload malformado → ignora
    }
  }

  void _scheduleReconnect() {
    _sub?.cancel();
    _sub = null;
    _channel = null;
    if (_disposed) return;
    Future.delayed(const Duration(seconds: 3), () {
      if (!_disposed) connect();
    });
  }

  void disconnect() {
    _disposed = true;
    _sub?.cancel();
    _channel?.sink.close();
    _sub = null;
    _channel = null;
  }
}
