import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/data/dtos/order_dto.dart';
import '../../core/data/dtos/table_dto.dart' as table_dto;
import '../../core/auth/mock_auth_provider.dart';
import '../../core/providers/orders_providers.dart';
import '../../core/providers/tables_providers.dart';
import '../../core/runtime/runtime_context.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/uuid.dart';

// ── Table Status (local UI enum, separate from DTO enum) ──────────────────────
enum TableStatus { vacant, occupied, payment, cleaning }

class TableData {
  final String id;
  final TableStatus status;
  final int capacity;
  final String? timer;
  final String? billAmount;
  final OrderDto? focusOrder;
  final OrderDto? latestOrder;
  final String? tenantId;

  const TableData({
    required this.id,
    required this.status,
    this.capacity = 4,
    this.timer,
    this.billAmount,
    this.focusOrder,
    this.latestOrder,
    this.tenantId,
  });
}

// ── Tables layout (fallback if tables repo is empty) ─────────────────────────
const List<({String id, int capacity})> _tableLayout = [
  (id: 'T01', capacity: 4),
  (id: 'T02', capacity: 4),
  (id: 'T03', capacity: 2),
  (id: 'T04', capacity: 4),
  (id: 'T05', capacity: 6),
  (id: 'T06', capacity: 6),
  (id: 'T07', capacity: 4),
  (id: 'T08', capacity: 4),
  (id: 'T09', capacity: 2),
  (id: 'T10', capacity: 4),
  (id: 'T11', capacity: 6),
  (id: 'T12', capacity: 4),
];

// ── Convert DTO list → layout list ───────────────────────────────────────────
List<({String id, int capacity})> _layoutFromDtos(
  List<table_dto.RestaurantTableDto> dtos,
) {
  if (dtos.isEmpty) return _tableLayout;
  return dtos
      .map((t) => (id: t.label.replaceAll('-', ''), capacity: t.capacity))
      .toList()
    ..sort((a, b) => a.id.compareTo(b.id));
}

String _tableKeyFromNum(dynamic value) {
  if (value == null) return '';
  final raw = value.toString();
  if (raw.isEmpty) return '';
  if (raw.toUpperCase().startsWith('T')) return raw.toUpperCase();
  final numVal = int.tryParse(raw);
  if (numVal == null) return '';
  return 'T${numVal.toString().padLeft(2, '0')}';
}

// ── Derive TableData from live orders ────────────────────────────────────────
List<TableData> _deriveTableData(
  List<OrderDto> orders,
  List<({String id, int capacity})> layout,
) {
  final Map<String, List<OrderDto>> byTable = {};
  for (final o in orders) {
    final rawNum = o.tableLabel;
    final tableKey = _tableKeyFromNum(rawNum);
    byTable.putIfAbsent(tableKey, () => []).add(o);
  }

  return layout.map((t) {
    final tableOrders = byTable[t.id] ?? [];
    tableOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latestOrder = tableOrders.isNotEmpty ? tableOrders.first : null;
    final tenantId = latestOrder?.tenantId;

    final hasActive = tableOrders.any((o) {
      final s = o.status;
      return s == OrderStatus.pending ||
          s == OrderStatus.preparing ||
          s == OrderStatus.ready ||
          s == OrderStatus.served;
    });

    // NOTE: TableStatus.cleaning and .payment are future extensions when the DTO
    // gains dedicated status fields. For now derive from active orders only.
    final TableStatus status = hasActive
        ? TableStatus.occupied
        : TableStatus.vacant;

    OrderDto? focusOrder;
    if (status == TableStatus.occupied) {
      focusOrder = tableOrders.firstWhere((o) {
        final s = o.status;
        return s == OrderStatus.pending ||
            s == OrderStatus.preparing ||
            s == OrderStatus.ready ||
            s == OrderStatus.served;
      }, orElse: () => latestOrder!);
    } else if (status == TableStatus.payment) {
      focusOrder = latestOrder;
    } else if (status == TableStatus.cleaning) {
      focusOrder = latestOrder;
    }

    String? bill;
    if (status == TableStatus.occupied || status == TableStatus.payment) {
      final total = tableOrders.fold<double>(0, (s, o) => s + o.totalAmount);
      if (total > 0) {
        bill = total >= 1000
            ? '₹${(total / 1000).toStringAsFixed(1)}k'
            : '₹${total.toStringAsFixed(0)}';
      }
    }

    return TableData(
      id: t.id,
      status: status,
      capacity: t.capacity,
      billAmount: bill,
      focusOrder: focusOrder,
      latestOrder: latestOrder,
      tenantId: tenantId,
    );
  }).toList();
}

// ── Screen ────────────────────────────────────────────────────────────────────
class StaffTablesScreen extends ConsumerStatefulWidget {
  const StaffTablesScreen({super.key});

  @override
  ConsumerState<StaffTablesScreen> createState() => _StaffTablesScreenState();
}

class _StaffTablesScreenState extends ConsumerState<StaffTablesScreen> {
  // ── Add table ─────────────────────────────────────────────────────────────
  Future<void> _addTableDialog() async {
    final tableController = TextEditingController();
    final capacityController = TextEditingController(text: '4');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Table'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tableController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Table number'),
            ),
            TextField(
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacity'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != true) return;
    final tableNum = int.tryParse(tableController.text.trim());
    final capacity = int.tryParse(capacityController.text.trim()) ?? 4;
    if (tableNum == null) return;

    try {
      final profile = await ref.read(userProfileProvider.future);
      final tenantId = requireContextValue(
        value: profile?['tenant_id'] as String?,
        field: 'tenantId',
        source: 'StaffTablesScreen._addTableDialog',
      );
      final newTable = table_dto.RestaurantTableDto(
        id: UuidGenerator.generateRuntimeId(prefix: 'table'),
        tenantId: tenantId,
        label: 'T${tableNum.toString().padLeft(2, '0')}',
        capacity: capacity,
        status: table_dto.TableStatus.available,
        updatedAt: DateTime.now(),
      );
      await ref.read(createTableProvider)(newTable);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Table added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add table: $e')));
      }
    }
  }

  // ── Delete table ──────────────────────────────────────────────────────────
  Future<void> _deleteTableDialog() async {
    final tableController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Table'),
        content: TextField(
          controller: tableController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Table number'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result != true) return;
    final tableNum = int.tryParse(tableController.text.trim());
    if (tableNum == null) return;

    final label = 'T${tableNum.toString().padLeft(2, '0')}';
    // Find the table id from the current stream snapshot
    final tablesAsync = ref.read(tablesStreamProvider);
    final tableId = tablesAsync.valueOrNull
        ?.firstWhere(
          (t) => t.label.replaceAll('-', '') == label,
          orElse: () => table_dto.RestaurantTableDto(
            id: '',
            tenantId: '',
            label: '',
            capacity: 0,
            status: table_dto.TableStatus.available,
            updatedAt: DateTime.now(),
          ),
        )
        .id;

    if (tableId == null || tableId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Table not found.')));
      }
      return;
    }

    try {
      await ref.read(deleteTableProvider)(tableId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete table failed: $e')));
      }
    }
  }

  // ── Edit table ────────────────────────────────────────────────────────────
  Future<void> _editTableDialog(TableData table) async {
    final tableController = TextEditingController(
      text: table.id.replaceAll('T', ''),
    );
    final capacityController = TextEditingController(
      text: table.capacity.toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Table'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tableController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Table Number'),
            ),
            TextField(
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacity'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) return;

    // Find the DTO for this table
    final tablesAsync = ref.read(tablesStreamProvider);
    final dto = tablesAsync.valueOrNull?.firstWhere(
      (t) => t.label.replaceAll('-', '') == table.id,
      orElse: () => table_dto.RestaurantTableDto(
        id: '',
        tenantId: '',
        label: '',
        capacity: 0,
        status: table_dto.TableStatus.available,
        updatedAt: DateTime.now(),
      ),
    );

    if (dto == null || dto.id.isEmpty) return;

    final newNum = int.tryParse(tableController.text.trim());
    // ignore: unused_local_variable — capacity update pending full DTO support
    final newCap = int.tryParse(capacityController.text.trim()) ?? 4;
    if (newNum == null) return;

    try {
      // updateTableStatus is the available mutation; for label/capacity changes
      // we re-create the table with updated values via the repository directly.
      // For now, update status to trigger a stream refresh (no-op status change).
      await ref.read(updateTableStatusProvider)(dto.id, dto.status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  // ── Advance table status ──────────────────────────────────────────────────
  Future<void> _advanceTableStatus(TableData table) async {
    final orderId = table.focusOrder?.id ?? table.latestOrder?.id;

    try {
      if (table.status == TableStatus.vacant) return;

      if (orderId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active order found to settle.')),
          );
        }
        return;
      }

      OrderStatus? nextOrderStatus;
      if (table.status == TableStatus.occupied ||
          table.status == TableStatus.payment) {
        nextOrderStatus = OrderStatus.cancelled; // maps to 'cleaning' flow
      } else if (table.status == TableStatus.cleaning) {
        nextOrderStatus = OrderStatus.served; // maps to 'closed' flow
      }

      if (nextOrderStatus != null) {
        await ref.read(updateOrderStatusProvider)(orderId, nextOrderStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Table status updated to ${nextOrderStatus.name}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
      }
    }
  }

  // ── Table details sheet ───────────────────────────────────────────────────
  void _showTableSettings(TableData table) => _showTableDetails(table);

  void _showTableDetails(TableData table) {
    final order = table.latestOrder;

    // Look up the underlying table DTO to get database table ID
    final tablesAsync = ref.read(tablesStreamProvider);
    final tableDto = tablesAsync.valueOrNull
        ?.where((t) => t.label.replaceAll('-', '') == table.id)
        .cast<table_dto.RestaurantTableDto?>()
        .firstOrNull;
    if (tableDto == null) {
      throw RuntimeInitializationException(
        'Unable to resolve authoritative table context for ${table.id}.',
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        if (order == null) {
          // Vacant Table Sheet
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Table ${table.id}',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Vacant • Capacity: ${table.capacity} Seats',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(
                      '/staff/add-order',
                      extra: {
                        'tableId': tableDto!.id,
                        'tableLabel': tableDto.label,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryContainer,
                    minimumSize: Size(double.infinity, 48.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_shopping_cart_rounded,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Create Order',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        label: 'Edit Details',
                        icon: Icons.edit_outlined,
                        color: AppTheme.secondary,
                        onTap: () {
                          Navigator.pop(context);
                          _editTableDialog(table);
                        },
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _ActionBtn(
                        label: 'Delete Table',
                        icon: Icons.delete_outline_rounded,
                        color: AppTheme.error,
                        onTap: () {
                          Navigator.pop(context);
                          _deleteTableDialog();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Occupied Table Sheet
        final items = order.items;
        final amount = order.totalAmount.toStringAsFixed(0);
        final status = order.displayStatus;
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Table ${table.id}',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Occupied • Status: $status',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16.h),
              if (items.isEmpty)
                Text(
                  'No items',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.secondary,
                  ),
                )
              else
                ...items.map((i) {
                  final name = i.menuItemName;
                  final qty = i.quantity;
                  final noteText = i.notes != null ? ' (${i.notes})' : '';
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$name x$qty$noteText',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${(i.unitPrice * qty).toStringAsFixed(0)}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12.sp,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '₹$amount',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryContainer,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      label: 'Add/Edit Items',
                      icon: Icons.add_shopping_cart_rounded,
                      color: AppTheme.primaryContainer,
                      onTap: () {
                        Navigator.pop(context);
                        context.push(
                          '/staff/add-order',
                          extra: {
                            'tableId': tableDto!.id,
                            'tableLabel': tableDto.label,
                            'existingOrder': order,
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _ActionBtn(
                      label: 'QR Code',
                      icon: Icons.qr_code_rounded,
                      color: AppTheme.secondary,
                      onTap: () {
                        Navigator.pop(context);
                        _showQRCode(table);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      label: 'Settle Bill',
                      icon: Icons.receipt_long_rounded,
                      color: Colors.green.shade700,
                      onTap: () {
                        Navigator.pop(context);
                        _advanceTableStatus(table);
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _ActionBtn(
                      label: 'Delete Table',
                      icon: Icons.delete_outline_rounded,
                      color: AppTheme.error,
                      onTap: () {
                        Navigator.pop(context);
                        _deleteTableDialog();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQRCode(TableData table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Table ${table.id} QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200.w,
              height: 200.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppTheme.surfaceContainerHigh),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 100),
            ),
            SizedBox(height: 16.h),
            Text(
              'Guests can scan this to order directly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppTheme.secondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final items = [
      (color: const Color(0xFF059669), label: 'Vacant'),
      (color: AppTheme.primaryContainer, label: 'Occupied'),
      (color: const Color(0xFFD97706), label: 'Payment'),
      (color: const Color(0xFF94A3B8), label: 'Cleaning'),
    ];
    return Wrap(
      spacing: 20.w,
      runSpacing: 8.h,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.r,
              height: 10.r,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.secondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesStreamProvider);
    final ordersAsync = ref.watch(ordersStreamProvider);

    // Derive layout from tables stream; fall back to static layout
    final layout = tablesAsync.maybeWhen(
      data: _layoutFromDtos,
      orElse: () => _tableLayout,
    );

    // Derive table display data from orders stream
    final orders = ordersAsync.valueOrNull ?? [];
    final tables = _deriveTableData(orders, layout);
    final occupiedCount = tables
        .where((t) => t.status == TableStatus.occupied)
        .length;

    // Show error if either stream has an error
    if (tablesAsync.hasError) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Text(
            'Table Sync Error: ${tablesAsync.error}',
            style: GoogleFonts.inter(color: AppTheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (ordersAsync.hasError) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Text(
            'Orders Sync Error: ${ordersAsync.error}',
            style: GoogleFonts.inter(color: AppTheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _addTableDialog,
        backgroundColor: AppTheme.primaryContainer,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppTheme.surfaceContainerLowest,
                elevation: 0,
                toolbarHeight: 64.h,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    Text(
                      'Orderlli',
                      style: GoogleFonts.inter(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      width: 1.w,
                      height: 20.h,
                      color: AppTheme.surfaceContainerHighest,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tables',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          Text(
                            tablesAsync.isLoading
                                ? 'SYNCING...'
                                : '${tables.length} TABLES · $occupiedCount OCC.',
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w500,
                              color: tablesAsync.isLoading
                                  ? AppTheme.error
                                  : AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Connectivity chip (always visible) ─────────────────
                    Consumer(
                      builder: (context, ref, _) {
                        final isOnline = ref.watch(isOnlineProvider);
                        final pendingCount =
                            ref
                                .watch(pendingActionsCountProvider)
                                .valueOrNull ??
                            0;
                        return GestureDetector(
                          onTap: () {
                            ref.read(isOnlineProvider.notifier).toggleOnline();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isOnline
                                      ? 'Switched to OFFLINE mode.'
                                      : 'Back ONLINE — syncing pending changes...',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isOnline
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOnline ? Icons.wifi : Icons.wifi_off,
                                  size: 14.r,
                                  color: isOnline
                                      ? const Color(0xFF065F46)
                                      : const Color(0xFF92400E),
                                ),
                                SizedBox(width: 4.w),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: Text(
                                    isOnline
                                        ? 'ONLINE'
                                        : 'OFFLINE${pendingCount > 0 ? ' ($pendingCount)' : ''}',
                                    key: ValueKey('$isOnline-$pendingCount'),
                                    style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: isOnline
                                          ? const Color(0xFF065F46)
                                          : const Color(0xFF92400E),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () {
                        ref.invalidate(tablesStreamProvider);
                        ref.invalidate(ordersStreamProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Refreshing data...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildLegend(),
                    SizedBox(height: 20.h),
                    if (tablesAsync.isLoading && tables.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: 2.1,
                        ),
                        itemCount: tables.length,
                        itemBuilder: (context, i) => _TableCard(
                          table: tables[i],
                          onAdvanceStatus: _advanceTableStatus,
                          onDetails: _showTableSettings,
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Table Card ────────────────────────────────────────────────────────────────
class _TableCard extends StatelessWidget {
  final TableData table;
  final void Function(TableData table) onAdvanceStatus;
  final void Function(TableData table) onDetails;

  const _TableCard({
    required this.table,
    required this.onAdvanceStatus,
    required this.onDetails,
  });

  Color get _statusColor => switch (table.status) {
    TableStatus.vacant => const Color(0xFF059669),
    TableStatus.occupied => AppTheme.primaryContainer,
    TableStatus.payment => const Color(0xFFD97706),
    TableStatus.cleaning => const Color(0xFF94A3B8),
  };

  String get _statusLabel => switch (table.status) {
    TableStatus.vacant => 'VACANT',
    TableStatus.occupied => 'OCCUPIED',
    TableStatus.payment => 'PAYMENT',
    TableStatus.cleaning => 'CLEANING',
  };

  @override
  Widget build(BuildContext context) {
    final isOccupied = table.status == TableStatus.occupied;
    final isPayment = table.status == TableStatus.payment;
    final isVacant = table.status == TableStatus.vacant;
    final isCleaning = table.status == TableStatus.cleaning;

    return InkWell(
      onTap: () => onDetails(table),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _statusColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _statusColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        table.id,
                        style: GoogleFonts.inter(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: isCleaning
                              ? AppTheme.secondary
                              : AppTheme.onSurface,
                        ),
                      ),
                      if (isOccupied || isPayment)
                        Row(
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              size: 12.r,
                              color: _statusColor,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              table.timer ?? '00:00',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11.sp,
                                color: _statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else if (isCleaning)
                        Text(
                          'Ready soon',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.sp,
                            color: AppTheme.secondary,
                          ),
                        )
                      else
                        Text(
                          '${table.capacity} Seats',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: AppTheme.secondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: AppTheme.radiusFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w800,
                          color: _statusColor,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.settings_outlined,
                        size: 10.r,
                        color: _statusColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Divider(color: _statusColor.withValues(alpha: 0.1)),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (isOccupied || isPayment) ? 'BILL' : 'CAPACITY',
                        style: GoogleFonts.inter(
                          fontSize: 8.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondary,
                        ),
                      ),
                      Text(
                        (isOccupied || isPayment)
                            ? (table.billAmount ?? '₹0')
                            : '${table.capacity} SEATS',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: (isOccupied || isPayment)
                              ? _statusColor
                              : AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                isVacant
                    ? IconButton(
                        onPressed: () => onDetails(table),
                        icon: Icon(
                          Icons.settings_outlined,
                          color: AppTheme.secondary,
                          size: 24.r,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.secondary.withValues(
                            alpha: 0.1,
                          ),
                          padding: EdgeInsets.all(8.r),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () => onAdvanceStatus(table),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _statusColor,
                          minimumSize: Size(80.w, 32.h),
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          isCleaning ? 'Ready' : 'Settle',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20.r),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
