// ── Order Status Enum ────────────────────────────────────────────────────────
// Serializable enum for order status.

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  served,
  cancelled;

  String toJson() => name;

  static OrderStatus fromJson(String json) => values.byName(json);

  static OrderStatus fromString(String value) => OrderStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => OrderStatus.pending,
  );

  bool get isActive =>
      this != OrderStatus.served && this != OrderStatus.cancelled;

  bool get isCompleted => this == OrderStatus.served;

  bool get isCancelled => this == OrderStatus.cancelled;
}
