// lib/core/network/offline_queue.dart
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'network_info.dart';
import '../utils/uuid.dart';

typedef OfflineWriteHandler = Future<void> Function(Map<String, dynamic> payload);

class OfflineQueueManager {
  final Box<String> _queueBox;
  final NetworkInfo _networkInfo;
  final Talker _talker;
  final Map<String, OfflineWriteHandler> _handlers = {};
  bool _isProcessing = false;

  OfflineQueueManager(this._queueBox, this._networkInfo, this._talker) {
    // Listen for network reconnect to auto-flush queue
    _networkInfo.onConnectionChanged.listen((isConnected) {
      if (isConnected) {
        _talker.info('Network connection restored. Flushing offline write queue...');
        processQueue();
      }
    });
  }

  void registerHandler(String action, OfflineWriteHandler handler) {
    _handlers[action] = handler;
  }

  Future<void> queueWrite({required String action, required Map<String, dynamic> payload}) async {
    final id = UuidGenerator.generateRuntimeId(prefix: 'offline-write');
    final item = {
      'id': id,
      'action': action,
      'payload': payload,
    };
    await _queueBox.put(id, jsonEncode(item));
    _talker.warning('Offline/Timeout: Queued write operation [$action] with ID: $id');
    
    // Attempt processing in case we are actually online
    if (await _networkInfo.isConnected) {
      await processQueue();
    }
  }

  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final keys = List<String>.from(_queueBox.keys);
      if (keys.isEmpty) {
        _isProcessing = false;
        return;
      }

      // Sort by key (timestamp-based ID) to ensure sequential FIFO execution
      keys.sort();

      for (final key in keys) {
        if (!await _networkInfo.isConnected) {
          _talker.warning('Connection lost while processing offline queue. Suspending.');
          break;
        }

        final raw = _queueBox.get(key);
        if (raw == null) continue;

        try {
          final item = Map<String, dynamic>.from(jsonDecode(raw));
          final action = item['action'] as String;
          final payload = Map<String, dynamic>.from(item['payload']);

          final handler = _handlers[action];
          if (handler != null) {
            _talker.info('Processing queued write [$action] (ID: $key)...');
            await handler(payload);
            await _queueBox.delete(key);
            _talker.info('Successfully executed and removed queued write [$action] (ID: $key)');
          } else {
            _talker.error('No handler registered for offline write action: $action. Skipping.');
            await _queueBox.delete(key);
          }
        } catch (e) {
          _talker.error('Failed to process offline write (ID: $key): $e. Will retry later.');
          break; // Stop execution on error to preserve FIFO ordering
        }
      }
    } finally {
      _isProcessing = false;
    }
  }
}
