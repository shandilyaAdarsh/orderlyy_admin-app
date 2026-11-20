import '../../../../core/config/app_config.dart';

class TableDto {
  final String id;
  final String tenantId;
  final String branchId;
  final String tableNumber;
  final String? displayName;
  final int capacity;
  final String? qrCodeToken;
  final String? qrUrl;
  final String? floorId;
  final String? sectionId;
  final bool isActive;
  final int versionNum;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final String? status;
  final String? currentSessionId;

  String get resolvedQrUrl => AppConfig.instance.normalizeCustomerQrUrl(
        qrUrl,
        fallbackToken: qrCodeToken ?? id,
      );

  const TableDto({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.tableNumber,
    this.displayName,
    required this.capacity,
    this.qrCodeToken,
    this.qrUrl,
    this.floorId,
    this.sectionId,
    required this.isActive,
    this.versionNum = 1,
    this.createdAt,
    this.updatedAt,
    this.assignedStaffId,
    this.assignedStaffName,
    this.status,
    this.currentSessionId,
  });

  TableDto copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? tableNumber,
    String? displayName,
    int? capacity,
    String? qrCodeToken,
    String? qrUrl,
    String? floorId,
    String? sectionId,
    bool? isActive,
    int? versionNum,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedStaffId,
    String? assignedStaffName,
    String? status,
    String? currentSessionId,
  }) {
    return TableDto(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      tableNumber: tableNumber ?? this.tableNumber,
      displayName: displayName ?? this.displayName,
      capacity: capacity ?? this.capacity,
      qrCodeToken: qrCodeToken ?? this.qrCodeToken,
      qrUrl: qrUrl ?? this.qrUrl,
      floorId: floorId ?? this.floorId,
      sectionId: sectionId ?? this.sectionId,
      isActive: isActive ?? this.isActive,
      versionNum: versionNum ?? this.versionNum,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      status: status ?? this.status,
      currentSessionId: currentSessionId ?? this.currentSessionId,
    );
  }

  factory TableDto.fromJson(Map<String, dynamic> json) => TableDto(
    id: json['id'] as String,
    tenantId: json['tenant_id'] as String,
    branchId: json['branch_id'] as String,
    tableNumber: json['table_number'] as String,
    displayName: json['display_name'] as String?,
    capacity: json['capacity'] as int,
    qrCodeToken: (json['qr_token'] ?? json['qr_code_token']) as String?,
    qrUrl: json['qr_url'] as String?,
    floorId: json['floor_id'] as String?,
    sectionId: json['section_id'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    versionNum: json['version_num'] as int? ?? 1,
    assignedStaffId: json['assigned_staff_id'] as String?,
    assignedStaffName: json['staff'] is Map
        ? (json['staff'] as Map)['name']?.toString()
        : json['assigned_staff_name']?.toString(),
    status: json['status'] as String?,
    currentSessionId: json['current_session_id'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'branch_id': branchId,
    'table_number': tableNumber,
    'display_name': displayName,
    'capacity': capacity,
    'qr_code_token': qrCodeToken,
    'qr_url': qrUrl,
    'floor_id': floorId,
    'section_id': sectionId,
    'is_active': isActive,
    'version_num': versionNum,
    'assigned_staff_id': assignedStaffId,
    'status': status,
    'current_session_id': currentSessionId,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
