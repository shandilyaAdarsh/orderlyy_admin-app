import '../../../../core/config/app_config.dart';

class RestaurantTable {
  final String id;
  final String tenantId;
  final String branchId;
  final String tableNumber;
  final String? tableName;
  final String? qrToken;
  final String? rawQrUrl;
  final DateTime? deletedAt;

  const RestaurantTable({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.tableNumber,
    this.tableName,
    this.qrToken,
    this.rawQrUrl,
    this.deletedAt,
  });

  String get qrUrl => AppConfig.instance.normalizeCustomerQrUrl(
        rawQrUrl,
        fallbackToken: qrToken ?? id,
      );

  factory RestaurantTable.fromJson(Map<String, dynamic> json) =>
      RestaurantTable(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        branchId: json['branch_id'] as String,
        tableNumber: json['table_number'].toString(),
        tableName: json['display_name'] as String?,
        qrToken: (json['qr_token'] ?? json['qr_code_token']) as String?,
        rawQrUrl: json['qr_url'] as String?,
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
      );
}
