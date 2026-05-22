// ── Orders Domain DTOs ────────────────────────────────────────────────────────
// API-compatible. All enums are string-backed to match future JSON payloads.

library;

// ── Order status enum ─────────────────────────────────────────────────────────

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  served,
  cancelled;

  static OrderStatus fromString(String value) => OrderStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => OrderStatus.pending,
  );
}

// ── Order item ────────────────────────────────────────────────────────────────

class OrderItemDto {
  final String id;
  final String menuItemId;
  final String menuItemName;
  final int quantity;
  final double unitPrice;
  final String? notes;

  const OrderItemDto({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.unitPrice,
    this.notes,
  });

  double get lineTotal => unitPrice * quantity;

  factory OrderItemDto.fromJson(Map<String, dynamic> json) => OrderItemDto(
    id: json['id'] as String,
    menuItemId: json['menu_item_id'] as String,
    menuItemName: json['menu_item_name'] as String,
    quantity: json['quantity'] as int,
    unitPrice: (json['unit_price'] as num).toDouble(),
    notes: json['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'menu_item_id': menuItemId,
    'menu_item_name': menuItemName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'notes': notes,
  };
}

// ── Order ─────────────────────────────────────────────────────────────────────

class OrderDto {
  final String id;
  final String tenantId;
  final String tableId;
  final String tableLabel;
  final OrderStatus status;
  final List<OrderItemDto> items;
  final double totalAmount;
  final String? staffId;
  final String? staffName;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderDto({
    required this.id,
    required this.tenantId,
    required this.tableId,
    required this.tableLabel,
    required this.status,
    required this.items,
    required this.totalAmount,
    this.staffId,
    this.staffName,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) => OrderDto(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    tableId: json['table_id'] as String? ?? '',
    tableLabel: json['table_label'] as String? ?? 'T??',
    status: OrderStatus.fromString(json['status'] as String),
    items: (json['items'] as List? ?? [])
        .map((e) => OrderItemDto.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalAmount: (json['total_amount'] as num).toDouble(),
    staffId: json['staff_id'] as String?,
    staffName: json['staff_name'] as String?,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'table_id': tableId,
    'table_label': tableLabel,
    'status': status.name,
    'items': items.map((i) => i.toJson()).toList(),
    'total_amount': totalAmount,
    'staff_id': staffId,
    'staff_name': staffName,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  OrderDto copyWith({OrderStatus? status, DateTime? updatedAt}) => OrderDto(
    id: id,
    tenantId: tenantId,
    tableId: tableId,
    tableLabel: tableLabel,
    status: status ?? this.status,
    items: items,
    totalAmount: totalAmount,
    staffId: staffId,
    staffName: staffName,
    notes: notes,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  String get displayStatus => status.name.toUpperCase();

  String get displayTime {
    final dt = createdAt.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day} · $hour:$minute $ampm';
  }
}
