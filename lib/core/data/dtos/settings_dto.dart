// ── Tenant Settings DTO ────────────────────────────────────────────────────────

class TenantSettingsDto {
  final String tenantId;
  final bool notifyNewOrder;
  final bool notifyOrderReady;
  final bool notifyLowStock;
  final bool notifyRevenue;
  final bool printReceipt;
  final bool autoAccept;
  final String confirmationSound;
  final bool qrAutoAssign;
  final String gstNumber;
  final double taxPercentage;
  final DateTime updatedAt;

  const TenantSettingsDto({
    required this.tenantId,
    required this.notifyNewOrder,
    required this.notifyOrderReady,
    required this.notifyLowStock,
    required this.notifyRevenue,
    required this.printReceipt,
    required this.autoAccept,
    required this.confirmationSound,
    required this.qrAutoAssign,
    required this.gstNumber,
    required this.taxPercentage,
    required this.updatedAt,
  });

  factory TenantSettingsDto.fromJson(Map<String, dynamic> json) =>
      TenantSettingsDto(
        tenantId: json['tenant_id'] as String,
        notifyNewOrder: json['notify_new_order'] as bool? ?? true,
        notifyOrderReady: json['notify_order_ready'] as bool? ?? true,
        notifyLowStock: json['notify_low_stock'] as bool? ?? false,
        notifyRevenue: json['notify_revenue'] as bool? ?? false,
        printReceipt: json['print_receipt'] as bool? ?? true,
        autoAccept: json['auto_accept'] as bool? ?? false,
        confirmationSound: json['confirmation_sound'] as String? ?? 'BEEP_01',
        qrAutoAssign: json['qr_auto_assign'] as bool? ?? true,
        gstNumber: json['gst_number'] as String? ?? '',
        taxPercentage: (json['tax_percentage'] as num?)?.toDouble() ?? 5.0,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'tenant_id': tenantId,
    'notify_new_order': notifyNewOrder,
    'notify_order_ready': notifyOrderReady,
    'notify_low_stock': notifyLowStock,
    'notify_revenue': notifyRevenue,
    'print_receipt': printReceipt,
    'auto_accept': autoAccept,
    'confirmation_sound': confirmationSound,
    'qr_auto_assign': qrAutoAssign,
    'gst_number': gstNumber,
    'tax_percentage': taxPercentage,
    'updated_at': updatedAt.toIso8601String(),
  };

  TenantSettingsDto copyWith({
    String? tenantId,
    bool? notifyNewOrder,
    bool? notifyOrderReady,
    bool? notifyLowStock,
    bool? notifyRevenue,
    bool? printReceipt,
    bool? autoAccept,
    String? confirmationSound,
    bool? qrAutoAssign,
    String? gstNumber,
    double? taxPercentage,
    DateTime? updatedAt,
  }) {
    return TenantSettingsDto(
      tenantId: tenantId ?? this.tenantId,
      notifyNewOrder: notifyNewOrder ?? this.notifyNewOrder,
      notifyOrderReady: notifyOrderReady ?? this.notifyOrderReady,
      notifyLowStock: notifyLowStock ?? this.notifyLowStock,
      notifyRevenue: notifyRevenue ?? this.notifyRevenue,
      printReceipt: printReceipt ?? this.printReceipt,
      autoAccept: autoAccept ?? this.autoAccept,
      confirmationSound: confirmationSound ?? this.confirmationSound,
      qrAutoAssign: qrAutoAssign ?? this.qrAutoAssign,
      gstNumber: gstNumber ?? this.gstNumber,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
