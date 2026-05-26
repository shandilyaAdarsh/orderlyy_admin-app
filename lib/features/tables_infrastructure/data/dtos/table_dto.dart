class TableDto {
  final String id;
  final String tenantId;
  final String branchId;
  final String label;
  final int capacity;
  final String qrCodeToken;
  final String sectionId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TableDto({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.label,
    required this.capacity,
    required this.qrCodeToken,
    required this.sectionId,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  TableDto copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? label,
    int? capacity,
    String? qrCodeToken,
    String? sectionId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TableDto(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      label: label ?? this.label,
      capacity: capacity ?? this.capacity,
      qrCodeToken: qrCodeToken ?? this.qrCodeToken,
      sectionId: sectionId ?? this.sectionId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TableDto.fromJson(Map<String, dynamic> json) => TableDto(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String,
        branchId: json['branch_id'] as String,
        label: json['label'] as String,
        capacity: json['capacity'] as int,
        qrCodeToken: json['qr_code_token'] as String,
        sectionId: json['section_id'] as String,
        isActive: json['is_active'] as bool? ?? true,
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
        'label': label,
        'capacity': capacity,
        'qr_code_token': qrCodeToken,
        'section_id': sectionId,
        'is_active': isActive,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
