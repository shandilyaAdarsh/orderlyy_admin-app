import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dtos/sync_action.dart';
import '../dtos/order_dto.dart';

class OfflineSyncQueue {
  static const String _kQueueKey = 'offline_sync_pending_queue';
  static const String _kOrdersCacheKey = 'offline_sync_orders_cache';
  static const String _kOnlineStatusKey = 'offline_sync_is_online';

  final SharedPreferences _prefs;

  OfflineSyncQueue(this._prefs);

  // ── Pending Actions Queue ──────────────────────────────────────────────────
  Future<List<SyncAction>> getQueue() async {
    try {
      final list = _prefs.getStringList(_kQueueKey);
      if (list == null) return [];
      return list
          .map(
            (s) => SyncAction.fromJson(jsonDecode(s) as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('[OfflineSyncQueue] Error reading queue: $e');
      return [];
    }
  }

  Future<void> enqueue(SyncAction action) async {
    try {
      final queue = await getQueue();
      queue.add(action);
      await _saveQueue(queue);
      debugPrint(
        '[OfflineSyncQueue] Enqueued action: ${action.type} (idempotencyKey: ${action.idempotencyKey})',
      );
    } catch (e) {
      debugPrint('[OfflineSyncQueue] Error enqueuing action: $e');
    }
  }

  Future<void> dequeue(String actionId) async {
    try {
      final queue = await getQueue();
      queue.removeWhere((a) => a.id == actionId);
      await _saveQueue(queue);
      debugPrint('[OfflineSyncQueue] Dequeued action: $actionId');
    } catch (e) {
      debugPrint('[OfflineSyncQueue] Error dequeuing action: $e');
    }
  }

  Future<void> clearQueue() async {
    await _prefs.remove(_kQueueKey);
  }

  Future<void> _saveQueue(List<SyncAction> queue) async {
    final list = queue.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList(_kQueueKey, list);
  }

  // ── Cached Orders ──────────────────────────────────────────────────────────
  Future<List<OrderDto>> getCachedOrders() async {
    try {
      final list = _prefs.getStringList(_kOrdersCacheKey);
      if (list == null) return [];
      return list
          .map((s) => OrderDto.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[OfflineSyncQueue] Error reading orders cache: $e');
      return [];
    }
  }

  Future<void> cacheOrders(List<OrderDto> orders) async {
    try {
      final list = orders.map((o) => jsonEncode(o.toJson())).toList();
      await _prefs.setStringList(_kOrdersCacheKey, list);
      debugPrint('[OfflineSyncQueue] Cached ${orders.length} orders locally');
    } catch (e) {
      debugPrint('[OfflineSyncQueue] Error caching orders: $e');
    }
  }

  // ── Connection Status (Manual simulator/Auto flag) ──────────────────────
  bool isOnline() {
    return _prefs.getBool(_kOnlineStatusKey) ?? true; // default online
  }

  Future<void> setOnlineStatus(bool online) async {
    await _prefs.setBool(_kOnlineStatusKey, online);
    debugPrint('[OfflineSyncQueue] Status changed online = $online');
  }
}
