// ── Tables Domain DTOs ────────────────────────────────────────────────────────
// API-compatible. Matches future backend contract.

library;

// ── Table status ──────────────────────────────────────────────────────────────

enum TableStatus {
  available,
  occupied,
  reserved,
  needsAttention,
  cleaning;

  static TableStatus fromString(String value) => TableStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => TableStatus.available,
  );

  String get displayName {
    switch (this) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.reserved:
        return 'Reserved';
      case TableStatus.needsAttention:
        return 'Needs Attention';
      case TableStatus.cleaning:
        return 'Cleaning';
    }
  }
}

// ── Table ─────────────────────────────────────────────────────────────────────

class RestaurantTableDto {
  final String id;
  final String tenantId;
  final String label; // e.g. "T-01", "Bar 3"
  final int capacity;
  final TableStatus status;
  final String? activeOrderId;
  final String? section; // e.g. "Indoor", "Patio"
  final DateTime updatedAt;

  const RestaurantTableDto({
    required this.id,
    required this.tenantId,
    required this.label,
    required this.capacity,
    required this.status,
    this.activeOrderId,
    this.section,
    required this.updatedAt,
  });

  factory RestaurantTableDto.fromJson(Map<String, dynamic> json) =>
      RestaurantTableDto(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        label: json['label'] as String,
        capacity: json['capacity'] as int,
        status: TableStatus.fromString(json['status'] as String),
        activeOrderId: json['active_order_id'] as String?,
        section: json['section'] as String?,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'label': label,
    'capacity': capacity,
    'status': status.name,
    'active_order_id': activeOrderId,
    'section': section,
    'updated_at': updatedAt.toIso8601String(),
  };

  RestaurantTableDto copyWith({
    TableStatus? status,
    String? activeOrderId,
    DateTime? updatedAt,
  }) => RestaurantTableDto(
    id: id,
    tenantId: tenantId,
    label: label,
    capacity: capacity,
    status: status ?? this.status,
    activeOrderId: activeOrderId ?? this.activeOrderId,
    section: section,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
