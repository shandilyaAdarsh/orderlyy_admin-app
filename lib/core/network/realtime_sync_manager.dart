// lib/core/network/realtime_sync_manager.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../features/orders/providers/orders_providers.dart';
import '../../features/orders/data/repositories/orders_repository_impl.dart';
import '../../features/orders/data/dtos/order_dto.dart';
import '../../features/tables/providers/tables_providers.dart';
import '../../features/tables/data/repositories/tables_repository_impl.dart';
import '../../features/tables/data/dtos/table_dto.dart';
import '../../features/waiter_calls/presentation/state/waiter_calls_providers.dart';
import '../../features/waiter_calls/data/repositories/waiter_calls_repository_impl.dart';
import '../../features/waiter_calls/domain/entities/waiter_call.dart';

class SyncEvent {
  final String idempotencyKey;
  final int sequenceNumber;
  final String type; // 'table_update', 'order_update', 'waiter_call'
  final Map<String, dynamic> payload;

  const SyncEvent({
    required this.idempotencyKey,
    required this.sequenceNumber,
    required this.type,
    required this.payload,
  });
}

class RealtimeSyncManager {
  final Ref ref;
  final Set<String> _processedKeys = {};
  int _expectedSequenceNumber = 1;
  bool _isReconnecting = false;
  WebSocketChannel? _channel;

  bool get isReconnecting => _isReconnecting;

  final StreamController<SyncEvent> _eventController = StreamController<SyncEvent>.broadcast();

  RealtimeSyncManager(this.ref) {
    // Start listening to the event processing pipeline
    _eventController.stream.listen(_processSyncEvent);

    // Establish WebSocket connection
    connectLocal();
  }

  Stream<SyncEvent> get eventStream => _eventController.stream;

  int get expectedSequenceNumber => _expectedSequenceNumber;

  void connectLocal() {
    debugPrint('[SYNC] Connecting to local sync server ws://localhost:8085...');
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8085'));
      _channel!.stream.listen(
        (message) {
          debugPrint('[SYNC] Received raw message: $message');
          try {
            final Map<String, dynamic> data = jsonDecode(message as String);
            receiveRawPayload(data);
          } catch (e) {
            debugPrint('[SYNC] Failed decoding message: $e');
          }
        },
        onDone: () {
          debugPrint('[SYNC] Local WebSocket closed. Reconnecting in 3 seconds...');
          Future.delayed(const Duration(seconds: 3), connectLocal);
        },
        onError: (err) {
          debugPrint('[SYNC] Local WebSocket error: $err. Reconnecting in 3s...');
          Future.delayed(const Duration(seconds: 3), connectLocal);
        },
      );
    } catch (e) {
      debugPrint('[SYNC] Connection exception: $e. Reconnecting in 3s...');
      Future.delayed(const Duration(seconds: 3), connectLocal);
    }
  }

  /// Simulates receiving a raw WebSocket message
  void receiveRawPayload(Map<String, dynamic> data) {
    try {
      final key = data['idempotencyKey'] as String?;
      final seqNum = data['sequenceNumber'] as int?;
      final type = data['type'] as String?;
      final payload = data['payload'] as Map<String, dynamic>?;

      if (key == null || seqNum == null || type == null || payload == null) {
        debugPrint('[SYNC] Invalid event envelope: $data');
        return;
      }

      final event = SyncEvent(
        idempotencyKey: key,
        sequenceNumber: seqNum,
        type: type,
        payload: payload,
      );

      _eventController.add(event);
    } catch (e) {
      debugPrint('[SYNC] Failed parsing WebSocket payload: $e');
    }
  }

  Future<void> _processSyncEvent(SyncEvent event) async {
    // 1. Idempotency Check (Duplicate Screening)
    if (_processedKeys.contains(event.idempotencyKey)) {
      debugPrint('[SYNC] Screened out duplicate event with key: ${event.idempotencyKey}');
      return;
    }
    _processedKeys.add(event.idempotencyKey);

    // 2. Sequence Verification
    if (event.sequenceNumber > _expectedSequenceNumber) {
      // Sequence break/gap detected!
      final gapStart = _expectedSequenceNumber;
      final gapEnd = event.sequenceNumber - 1;
      debugPrint('[SYNC] GAP DETECTED: expected $_expectedSequenceNumber, got ${event.sequenceNumber}. Fetching deltas from $gapStart to $gapEnd');
      await _fetchDeltaSync(gapStart, gapEnd);
      _expectedSequenceNumber = event.sequenceNumber + 1;
    } else if (event.sequenceNumber < _expectedSequenceNumber) {
      // Out of order old payload, ignore
      debugPrint('[SYNC] Out of order message. Sequence ${event.sequenceNumber} < $_expectedSequenceNumber. Ignoring.');
      return;
    } else {
      // Sequence matches expected sequence
      _expectedSequenceNumber = event.sequenceNumber + 1;
    }

    // 3. Dispatch payload to appropriate features
    _dispatchPayloadToProviders(event.type, event.payload);
  }

  Future<void> _fetchDeltaSync(int startSeq, int endSeq) async {
    _isReconnecting = true;
    debugPrint('[SYNC] Recovering delta states for sequence range [$startSeq..$endSeq]...');
    // Simulate latency for the REST api fallback fetch
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In a real implementation, we would query Supabase/REST for the missed updates.
    // For local simulation, we log this and complete the recovery.
    debugPrint('[SYNC] Delta state recovery complete.');
    _isReconnecting = false;
  }

  void _dispatchPayloadToProviders(String type, Map<String, dynamic> payload) {
    debugPrint('[SYNC] Dispatched event type: $type, payload: $payload');
    try {
      if (type == 'order_update') {
        final ordersRepo = ref.read(ordersRepositoryProvider) as OrdersRepositoryImpl;
        final staffOrderJson = _mapAdminOrderToStaffOrder(payload);
        final orderDto = OrderDto.fromJson(staffOrderJson);
        ordersRepo.local.cacheOrder(orderDto);
        debugPrint('[SYNC] Successfully updated order ${orderDto.id} locally.');
      } else if (type == 'table_update') {
        final tablesRepo = ref.read(tablesRepositoryProvider) as TablesRepositoryImpl;
        final staffTableJson = _mapAdminTableToStaffTable(payload);
        final tableDto = TableDto.fromJson(staffTableJson);
        tablesRepo.local.cacheTable(tableDto);
        debugPrint('[SYNC] Successfully updated table ${tableDto.id} locally.');
      } else if (type == 'table_delete') {
        final tablesRepo = ref.read(tablesRepositoryProvider) as TablesRepositoryImpl;
        final id = payload['id'] as String;
        tablesRepo.local.getCachedTables().then((currentList) {
          final updated = currentList.where((t) => t.id != id).toList();
          tablesRepo.local.cacheTables(updated);
        });
        debugPrint('[SYNC] Successfully deleted table $id locally.');
      } else if (type == 'waiter_call') {
        final waiterCallsRepo = ref.read(waiterCallsRepositoryProvider) as WaiterCallsRepositoryImpl;
        final call = WaiterCall(
          id: payload['id'] as String,
          tableId: payload['tableId'] as String,
          tableLabel: payload['tableLabel'] as String,
          type: CallType.values.firstWhere((e) => e.name == payload['type'] as String),
          status: CallStatus.values.firstWhere((e) => e.name == payload['status'] as String),
          customerNote: payload['customerNote'] as String?,
          timestamp: DateTime.parse(payload['timestamp'] as String),
          waiterId: payload['waiterId'] as String?,
          waiterName: payload['waiterName'] as String?,
          isVip: payload['isVip'] as bool? ?? false,
        );
        waiterCallsRepo.applyRemoteCallUpdate(call);
        debugPrint('[SYNC] Successfully updated waiter call ${call.id} locally.');
      } else if (type == 'waiter_call_delete') {
        final waiterCallsRepo = ref.read(waiterCallsRepositoryProvider) as WaiterCallsRepositoryImpl;
        final id = payload['id'] as String;
        waiterCallsRepo.applyRemoteCallDelete(id);
        debugPrint('[SYNC] Successfully deleted waiter call $id locally.');
      }
    } catch (e, stack) {
      debugPrint('[SYNC] Error dispatching payload to repository: $e\n$stack');
    }
  }

  // ── Admin-to-Staff DTO Mapping Helpers ─────────────────────────────────────
  Map<String, dynamic> _mapAdminItemToStaffItem(Map<String, dynamic> adminItem) {
    final priceInCents = ((adminItem['unit_price'] as num? ?? 0.0) * 100).round();
    return {
      'id': adminItem['id'],
      'product': {
        'id': adminItem['menu_item_id'],
        'name': adminItem['menu_item_name'] ?? 'Product',
        'priceInCents': priceInCents,
        'category': 'Mains',
        'availableModifiers': [],
      },
      'quantity': adminItem['quantity'] ?? 1,
      'selectedModifiers': [],
      'seatNumber': 1,
      'status': 'confirmed',
    };
  }

  Map<String, dynamic> _mapAdminOrderToStaffOrder(Map<String, dynamic> adminOrder) {
    final items = (adminOrder['items'] as List? ?? [])
        .map((item) => _mapAdminItemToStaffItem(item as Map<String, dynamic>))
        .toList();
    return {
      'id': adminOrder['id'],
      'tableId': adminOrder['table_id'] ?? '',
      'items': items,
      'status': adminOrder['status'] ?? 'pending',
      'createdAt': adminOrder['created_at'] ?? DateTime.now().toIso8601String(),
      'updatedAt': adminOrder['updated_at'] ?? DateTime.now().toIso8601String(),
      'waiterName': adminOrder['staff_name'] ?? 'John Doe',
      'cancelLogs': [],
    };
  }

  Map<String, dynamic> _mapAdminTableToStaffTable(Map<String, dynamic> adminTable) {
    return {
      'id': adminTable['id'],
      'label': adminTable['label'],
      'capacity': adminTable['capacity'],
      'status': adminTable['status'] ?? 'available',
      'active_order_id': adminTable['active_order_id'],
      'occupied_seats': adminTable['occupied_seats'] ?? [],
      'merged_table_ids': adminTable['merged_table_ids'] ?? [],
    };
  }

  void resetSequence(int startFrom) {
    _expectedSequenceNumber = startFrom;
    _processedKeys.clear();
    debugPrint('[SYNC] Sync sequence reset to: $_expectedSequenceNumber');
  }
}

// Global sync provider
final realtimeSyncManagerProvider = Provider<RealtimeSyncManager>((ref) {
  return RealtimeSyncManager(ref);
});
