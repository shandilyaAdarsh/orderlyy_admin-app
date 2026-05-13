import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

// ── Table Status ──────────────────────────────────────────────────────────────
enum TableStatus { vacant, occupied, payment, cleaning }

class TableData {
  final String id;
  final TableStatus status;
  final int capacity;
  final String? timer;
  final String? billAmount;
  final Map<String, dynamic>? focusOrder;
  final Map<String, dynamic>? latestOrder;
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

// ── Tables layout (fallback if tables table is empty) ───────────────────────
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

String _tableKeyFromNum(dynamic value) {
  if (value == null) return '';
  final raw = value.toString();
  if (raw.isEmpty) return '';
  if (raw.toUpperCase().startsWith('T')) return raw.toUpperCase();
  final numVal = int.tryParse(raw);
  if (numVal == null) return '';
  return 'T${numVal.toString().padLeft(2, '0')}';
}

List<({String id, int capacity})> _tableLayoutFromRows(
  List<Map<String, dynamic>> rows,
) {
  final layout = <({String id, int capacity})>[];
  for (final row in rows) {
    final key = _tableKeyFromNum(
      row['table_num'] ?? row['table_number'] ?? row['table_id'],
    );
    if (key.isEmpty) continue;
    final capacity = int.tryParse(row['capacity']?.toString() ?? '') ?? 4;
    layout.add((id: key, capacity: capacity));
  }
  layout.sort((a, b) => a.id.compareTo(b.id));
  return layout;
}

// Derive TableData list from live orders
List<TableData> _deriveTableData(
  List<Map<String, dynamic>> orders,
  List<({String id, int capacity})> layout,
) {
  // Group active orders by table_id
  final Map<String, List<Map<String, dynamic>>> byTable = {};
  for (final o in orders) {
    final rawNum = o['table_num'] ?? o['table_number'] ?? o['table_id'];
    if (rawNum == null) continue;
    final tableKey = _tableKeyFromNum(rawNum);
    byTable.putIfAbsent(tableKey, () => []).add(o);
  }
  debugPrint('DEBUG: Found orders for tables: ${byTable.keys.toList()}');

  return layout.map((t) {
    final tableOrders = byTable[t.id] ?? [];

    tableOrders.sort((a, b) {
      final ta = a['created_at']?.toString() ?? '';
      final tb = b['created_at']?.toString() ?? '';
      return tb.compareTo(ta);
    });
    final latestOrder = tableOrders.isNotEmpty ? tableOrders.first : null;
    final tenantId = latestOrder?['tenant_id']?.toString();

    // Check statuses
    final hasCleaning = tableOrders.any((o) {
      final s = (o['status'] ?? '').toString().toLowerCase();
      return s == 'cleaning';
    });
    final hasActive = tableOrders.any((o) {
      final s = (o['status'] ?? '').toString().toLowerCase();
      return s == 'pending' || s == 'cooking' || s == 'ready' || s == 'served';
    });
    final hasServedUnpaid = tableOrders.any((o) {
      final s = (o['status'] ?? '').toString().toLowerCase();
      return s == 'payment' || s == 'rejected';
    });

    TableStatus status;
    if (hasCleaning) {
      status = TableStatus.cleaning;
    } else if (hasActive) {
      status = TableStatus.occupied;
    } else if (hasServedUnpaid) {
      status = TableStatus.payment;
    } else {
      status = TableStatus.vacant;
    }

    Map<String, dynamic>? focusOrder;
    if (status == TableStatus.occupied) {
      focusOrder = tableOrders.firstWhere((o) {
        final s = (o['status'] ?? '').toString().toLowerCase();
        return s == 'pending' ||
            s == 'cooking' ||
            s == 'ready' ||
            s == 'served';
      }, orElse: () => latestOrder ?? <String, dynamic>{});
    } else if (status == TableStatus.payment) {
      focusOrder = tableOrders.firstWhere((o) {
        final s = (o['status'] ?? '').toString().toLowerCase();
        return s == 'payment' || s == 'rejected';
      }, orElse: () => latestOrder ?? <String, dynamic>{});
    } else if (status == TableStatus.cleaning) {
      focusOrder = tableOrders.firstWhere(
        (o) => (o['status'] ?? '').toString().toLowerCase() == 'cleaning',
        orElse: () => latestOrder ?? <String, dynamic>{},
      );
    }

    // Compute bill
    String? bill;
    if (status == TableStatus.occupied || status == TableStatus.payment) {
      final total = tableOrders.fold<double>(
        0,
        (s, o) => s + ((o['total_amount'] as num?)?.toDouble() ?? 0),
      );
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
      focusOrder: focusOrder != null && focusOrder.isNotEmpty
          ? focusOrder
          : null,
      latestOrder: latestOrder,
      tenantId: tenantId,
    );
  }).toList();
}

class StaffTablesScreen extends StatefulWidget {
  const StaffTablesScreen({super.key});

  @override
  State<StaffTablesScreen> createState() => _StaffTablesScreenState();
}

class _StaffTablesScreenState extends State<StaffTablesScreen> {
  String? _currentTenantId;

  // Return a safe stream for a table; if realtime stream creation fails
  // (for example if the table isn't present or realtime isn't configured),
  // fall back to a one-shot query stream so the UI remains usable.
  Stream<List<Map<String, dynamic>>> _safeStreamFor(String tableName) {
    try {
      return Supabase.instance.client
          .from(tableName)
          .stream(primaryKey: ['id'])
          .handleError((e) {
            debugPrint('Realtime stream error for $tableName: $e');
          });
    } catch (e) {
      debugPrint('Failed to create realtime stream for $tableName: $e');
      return Stream.fromFuture(_fetchOnce(tableName));
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOnce(String tableName) async {
    try {
      final data = await Supabase.instance.client.from(tableName).select();
      return List<Map<String, dynamic>>.from(data.cast<Map>());
    } catch (e) {
      debugPrint('One-shot fetch failed for $tableName: $e');
    }
    return <Map<String, dynamic>>[];
  }

  @override
  void initState() {
    super.initState();
    _loadTenantId();
  }

  Future<void> _loadTenantId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Try metadata first (fastest, no RLS)
      final metaTenant = user.userMetadata?['tenant_id']?.toString();
      if (metaTenant != null) {
        setState(() => _currentTenantId = metaTenant);
        debugPrint('DEBUG: Loaded Tenant ID from Metadata: $_currentTenantId');
        return;
      }

      // Try profile
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('tenant_id')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          setState(() => _currentTenantId = profile['tenant_id']?.toString());
          debugPrint('DEBUG: Loaded Tenant ID from Profile: $_currentTenantId');
          return;
        }
      } catch (e) {
        debugPrint('DEBUG: Profile fetch failed (likely RLS recursion): $e');
      }

      // Final fallback: Look at existing tables or orders to find your tenant_id
      final tableCheck = await Supabase.instance.client
          .from('tables')
          .select('tenant_id')
          .limit(1)
          .maybeSingle();

      if (tableCheck != null) {
        setState(() => _currentTenantId = tableCheck['tenant_id']?.toString());
        debugPrint(
          'DEBUG: Loaded Tenant ID from Tables fallback: $_currentTenantId',
        );
      }
    } catch (e) {
      debugPrint('Error loading tenant: $e');
    }
  }

  Future<void> _addTableDialog() async {
    final tableController = TextEditingController();
    final capacityController = TextEditingController(text: '4');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );

    if (result != true) return;
    final tableNum = int.tryParse(tableController.text.trim());
    final capacity = int.tryParse(capacityController.text.trim()) ?? 4;
    if (tableNum == null) return;

    final tenantId = _currentTenantId;
    if (tenantId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tenant not found.')));
      }
      return;
    }

    try {
      await Supabase.instance.client.from('tables').insert({
        'table_num': tableNum,
        'capacity': capacity,
        'tenant_id': tenantId,
        'is_active': true,
      });
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

  Future<void> _deleteTableDialog() async {
    final tableController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );

    if (result != true) return;
    final tableNum = int.tryParse(tableController.text.trim());
    if (tableNum == null) return;

    final tenantId = _currentTenantId;
    if (tenantId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tenant not found.')));
      }
      return;
    }

    try {
      await Supabase.instance.client
          .from('tables')
          .delete()
          .eq('table_num', tableNum)
          .eq('tenant_id', tenantId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete table failed: $e')));
      }
    }
  }

  int _tableNumFromId(String id) {
    final cleaned = id.toUpperCase().replaceAll('T', '');
    return int.tryParse(cleaned) ?? 0;
  }

  void _showTableSettings(TableData table) {
    // For now, settings on a vacant table could allow deleting or editing it
    _showTableDetails(table);
  }

  Future<void> _advanceTableStatus(TableData table) async {
    final orderId = table.focusOrder?['id'] ?? table.latestOrder?['id'];
    debugPrint(
      'DEBUG: Advancing status for table ${table.id}, Current Status: ${table.status}, OrderID: $orderId',
    );

    try {
      if (table.status == TableStatus.vacant) {
        debugPrint('DEBUG: Table is vacant, nothing to advance from here.');
        return;
      }

      if (orderId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active order found to settle.')),
          );
        }
        return;
      }

      String nextStatus = '';
      if (table.status == TableStatus.occupied ||
          table.status == TableStatus.payment) {
        nextStatus = 'cleaning';
      } else if (table.status == TableStatus.cleaning) {
        nextStatus = 'closed';
      }

      if (nextStatus.isNotEmpty) {
        debugPrint('DEBUG: Updating order $orderId to status: $nextStatus');
        final response = await Supabase.instance.client
            .from('orders')
            .update({'status': nextStatus})
            .eq('id', orderId)
            .select();

        debugPrint('DEBUG: Update response: $response');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Table status updated to $nextStatus')),
          );
        }
      }
    } catch (e) {
      debugPrint('DEBUG: Action failed error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
      }
    }
  }

  void _showTableDetails(TableData table) {
    final order = table.latestOrder;
    if (order == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No order details found.')));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final items = order['items'] is List ? order['items'] as List : [];
        final amount = order['total_amount']?.toString() ?? '0';
        final status = (order['status'] ?? 'PENDING').toString().toUpperCase();
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
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppTheme.secondary,
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
                  final name = i is Map ? (i['name'] ?? 'Item') : i.toString();
                  final qty = i is Map ? (i['quantity'] ?? 1) : 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      '$name x$qty',
                      style: GoogleFonts.inter(fontSize: 13.sp),
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
                    style: GoogleFonts.inter(
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
                      label: 'Edit',
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
                      label: 'QR Code',
                      icon: Icons.qr_code_rounded,
                      color: AppTheme.primaryContainer,
                      onTap: () {
                        Navigator.pop(context);
                        _showQRCode(table);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _ActionBtn(
                label: 'Delete Table',
                icon: Icons.delete_outline_rounded,
                color: AppTheme.error,
                onTap: () {
                  Navigator.pop(context);
                  _deleteTableDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

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

    if (result == true) {
      final newNum = int.tryParse(tableController.text.trim());
      final newCap = int.tryParse(capacityController.text.trim()) ?? 4;
      if (newNum != null && _currentTenantId != null) {
        try {
          await Supabase.instance.client
              .from('tables')
              .update({'table_num': newNum, 'capacity': newCap})
              .eq('table_num', _tableNumFromId(table.id))
              .eq('tenant_id', _currentTenantId!);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
          }
        }
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _safeStreamFor('tables'),
      builder: (context, tableSnapshot) {
        if (tableSnapshot.hasError) {
          debugPrint('Table Sync Error: ${tableSnapshot.error}');
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Text(
                'Table Sync Error: ${tableSnapshot.error}',
                style: GoogleFonts.inter(color: AppTheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final tableRows = tableSnapshot.data ?? [];
        final liveLayout = _tableLayoutFromRows(tableRows);
        final layout = liveLayout.isNotEmpty ? liveLayout : _tableLayout;

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _safeStreamFor('orders'),
          builder: (context, orderSnapshot) {
            if (orderSnapshot.hasError) {
              debugPrint('Orders Sync Error: ${orderSnapshot.error}');
              return Scaffold(
                backgroundColor: AppTheme.background,
                body: Center(
                  child: Text(
                    'Orders Sync Error: ${orderSnapshot.error}',
                    style: GoogleFonts.inter(color: AppTheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final orders = orderSnapshot.data ?? [];
            final tables = _deriveTableData(orders, layout);
            final occupiedCount = tables
                .where((t) => t.status == TableStatus.occupied)
                .length;
            debugPrint('DEBUG: Tables list length: ${tables.length}');
            if (tables.isNotEmpty) {
              debugPrint(
                'DEBUG: First table ID: ${tables.first.id}, Status: ${tables.first.status}',
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
                  builder: (context, constraints) => Stack(
                    children: [
                      CustomScrollView(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        _currentTenantId == null
                                            ? 'SYNCING...'
                                            : '${tables.length} TABLES · $occupiedCount OCC.',
                                        style: GoogleFonts.inter(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w500,
                                          color: _currentTenantId == null
                                              ? AppTheme.error
                                              : AppTheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh_rounded),
                                  onPressed: () {
                                    _loadTenantId();
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
                            padding: EdgeInsets.fromLTRB(
                              16.w,
                              16.h,
                              16.w,
                              100.h,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                _buildLegend(),
                                SizedBox(height: 20.h),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 1,
                                        mainAxisSpacing: 12.h,
                                        childAspectRatio: 2.1,
                                      ),
                                  itemCount: tables.length,
                                  itemBuilder: (context, i) {
                                    return _TableCard(
                                      table: tables[i],
                                      onAdvanceStatus: _advanceTableStatus,
                                      onDetails: _showTableSettings,
                                    );
                                  },
                                ),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

  Color get _statusColor {
    return switch (table.status) {
      TableStatus.vacant => const Color(0xFF059669),
      TableStatus.occupied => AppTheme.primaryContainer,
      TableStatus.payment => const Color(0xFFD97706),
      TableStatus.cleaning => const Color(0xFF94A3B8),
    };
  }

  String get _statusLabel {
    return switch (table.status) {
      TableStatus.vacant => 'VACANT',
      TableStatus.occupied => 'OCCUPIED',
      TableStatus.payment => 'PAYMENT',
      TableStatus.cleaning => 'CLEANING',
    };
  }

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
