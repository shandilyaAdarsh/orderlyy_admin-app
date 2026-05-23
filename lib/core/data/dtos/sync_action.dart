// No dart:convert needed — callers handle JSON encode/decode

class SyncAction {
  final String id;
  final String type; // 'createOrder' | 'updateOrder' | 'updateOrderStatus'
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final String idempotencyKey;

  SyncAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.timestamp,
    required this.idempotencyKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'idempotencyKey': idempotencyKey,
    };
  }

  factory SyncAction.fromJson(Map<String, dynamic> json) {
    return SyncAction(
      id: json['id'] as String,
      type: json['type'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      idempotencyKey: json['idempotencyKey'] as String,
    );
  }

  @override
  String toString() =>
      'SyncAction(id: $id, type: $type, idempotencyKey: $idempotencyKey)';
}
