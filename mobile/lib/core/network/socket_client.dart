import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../features/auth/providers/auth_provider.dart';
import '../constants/app_constants.dart';

final socketClientProvider = Provider<SocketClient>((ref) {
  final authState = ref.watch(authNotifierProvider).value;
  final token = authState?.token;
  
  final client = SocketClient(token);
  
  ref.onDispose(() {
    client.disconnect();
  });
  
  return client;
});

class SocketClient {
  IO.Socket? _socket;
  final String? token;

  SocketClient(this.token) {
    if (token != null) {
      _init();
    }
  }

  void _init() {
    final baseUrl = AppConstants.apiBaseUrl.replaceAll('/api/', '');
    _socket = IO.io(baseUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .enableReconnection()
        .setReconnectionAttempts(10)
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(30000)
        .setTimeout(20000)
        .setAuth({'token': 'Bearer $token'})
        .build());

    _socket?.onConnect((_) {
      developer.log('Socket connected', name: 'SocketClient');
    });

    _socket?.onConnectError((err) {
      developer.log('Socket connection error: $err', name: 'SocketClient', error: err);
    });

    _socket?.onDisconnect((_) {
      developer.log('Socket disconnected', name: 'SocketClient');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  IO.Socket? get socket => _socket;
}
