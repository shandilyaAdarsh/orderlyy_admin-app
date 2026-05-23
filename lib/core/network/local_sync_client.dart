import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LocalSyncClient {
  static bool enabled = !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

  static final LocalSyncClient _instance = LocalSyncClient._internal();
  factory LocalSyncClient() => _instance;
  LocalSyncClient._internal() {
    // Automatically trigger connection
    if (enabled) {
      connect();
    }
  }

  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isConnecting = false;

  bool get isConnected => _isConnected;

  void connect() {
    if (!enabled) return;
    if (_isConnected || _isConnecting) return;
    _isConnecting = true;
    if (kDebugMode) {
      print('[LocalSyncClient] Connecting to ws://localhost:8085...');
    }

    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8085'));
      
      // Listen to the channel's stream. In web_socket_channel v3, 
      // the channel is a WebSocketChannel wrapper that handles connection asynchronously.
      _channel!.stream.listen(
        (message) {
          if (!_isConnected) {
            _isConnected = true;
            _isConnecting = false;
            if (kDebugMode) {
              print('[LocalSyncClient] Connected to sync server.');
            }
          }
          if (kDebugMode) {
            print('[LocalSyncClient] Received message from server: $message');
          }
        },
        onDone: () {
          _isConnected = false;
          _isConnecting = false;
          if (kDebugMode) {
            print('[LocalSyncClient] WebSocket stream done. Reconnecting in 3s...');
          }
          Future.delayed(const Duration(seconds: 3), connect);
        },
        onError: (error) {
          _isConnected = false;
          _isConnecting = false;
          if (kDebugMode) {
            print('[LocalSyncClient] WebSocket stream error: $error. Reconnecting in 3s...');
          }
          Future.delayed(const Duration(seconds: 3), connect);
        },
      );

      // On some platforms (like Web), connection status is only known after first event or when sending.
      // So we assume connected, and if it fails, the stream's onError/onDone will trigger reconnection.
      _isConnected = true;
      _isConnecting = false;
    } catch (e) {
      _isConnected = false;
      _isConnecting = false;
      if (kDebugMode) {
        print('[LocalSyncClient] Exception during connection: $e. Reconnecting in 3s...');
      }
      Future.delayed(const Duration(seconds: 3), connect);
    }
  }

  void broadcastEvent(String type, Map<String, dynamic> payload) {
    if (!enabled) return;
    if (!_isConnected || _channel == null) {
      if (kDebugMode) {
        print('[LocalSyncClient] Client not connected. Trying to connect and dropping event: $type');
      }
      connect();
      return;
    }

    final event = {
      'idempotencyKey': DateTime.now().microsecondsSinceEpoch.toString(),
      'sequenceNumber': DateTime.now().millisecondsSinceEpoch,
      'type': type,
      'payload': payload,
    };

    try {
      _channel!.sink.add(jsonEncode(event));
      if (kDebugMode) {
        print('[LocalSyncClient] Broadcasted event: $type');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[LocalSyncClient] Error sending event: $e. Attempting reconnection...');
      }
      _isConnected = false;
      connect();
    }
  }
}
