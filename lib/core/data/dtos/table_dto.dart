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
  final String?
  sectionId; // Normalized reference to a section/floor, NOT tightly coupled to layout logic
  final DateTime updatedAt;
  final int versionNum;
  final DateTime? deletedAt;

  const RestaurantTableDto({
    required this.id,
    required this.tenantId,
    required this.label,
    required this.capacity,
    required this.status,
    this.activeOrderId,
    this.sectionId,
    required this.updatedAt,
    required this.versionNum,
    this.deletedAt,
  });

  factory RestaurantTableDto.fromJson(Map<String, dynamic> json) =>
      RestaurantTableDto(
        id: json['id']?.toString() ?? '',
        tenantId: json['tenant_id']?.toString() ?? '',
        label: (json['label'] ?? json['display_name'] ?? json['table_number'] ?? json['table_num'])?.toString() ?? 'T??',
        capacity: (json['capacity'] as num?)?.toInt() ?? 4,
        status: TableStatus.fromString(
          json['status']?.toString() ?? 'available',
        ),
        activeOrderId: json['active_order_id']?.toString(),
        sectionId: (json['section_id'] ?? json['floor'])?.toString(),
        updatedAt: DateTime.tryParse(
          json['updated_at']?.toString() ??
              json['created_at']?.toString() ??
              '',
        ) ?? DateTime.now(),
        versionNum: (json['version_num'] as num?)?.toInt() ?? 1,
        deletedAt: json['deleted_at'] != null
            ? DateTime.tryParse(json['deleted_at'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
    // id, updated_at, deleted_at handled by backend
    'tenant_id': tenantId,
    'label': label,
    'capacity': capacity,
    'status': status.name,
    'active_order_id': activeOrderId,
    'section_id': sectionId,
    'version_num': versionNum, // sent for OCC
  };

  RestaurantTableDto copyWith({
    TableStatus? status,
    String? activeOrderId,
    DateTime? updatedAt,
    int? versionNum,
  }) => RestaurantTableDto(
    id: id,
    tenantId: tenantId,
    label: label,
    capacity: capacity,
    status: status ?? this.status,
    activeOrderId: activeOrderId ?? this.activeOrderId,
    sectionId: sectionId,
    updatedAt: updatedAt ?? this.updatedAt,
    versionNum: versionNum ?? this.versionNum,
    deletedAt: deletedAt,
  );
}
