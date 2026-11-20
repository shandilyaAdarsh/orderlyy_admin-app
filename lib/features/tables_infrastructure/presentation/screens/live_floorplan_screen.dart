import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../state/table_infrastructure_providers.dart';
import '../../data/dtos/table_dto.dart';
import 'table_infrastructure_screen.dart';
import '../../../../core/providers/tables_providers.dart';

// ── Screen Class ──────────────────────────────────────────────────────────────
class LiveFloorplanScreen extends ConsumerWidget {
  const LiveFloorplanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesFutureProvider);
    final tablePositions = ref.watch(tablePositionsProvider);
    final floorsAsync = ref.watch(floorsFutureProvider);
    final activeFloorId = ref.watch(activeFloorIdProvider);
    final desktop = MediaQuery.of(context).size.width >= 960;

    floorsAsync.whenData((floors) {
      if (activeFloorId == null && floors.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(activeFloorIdProvider.notifier).state = floors.first.id;
        });
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Table & Floor Monitor',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Divider(
            height: 1.h,
            thickness: 1.h,
            color: AppTheme.surfaceContainerHigh,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: desktop ? 32.w : 16.w,
            vertical: 20.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Table & Floor Monitor',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: desktop ? 24.sp : 20.sp,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Operational dashboard tracking dining phases & service stages.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline_rounded,
                        color: AppTheme.primary, size: 28.r),
                    onPressed: () {
                      _showAddFloorDialog(context, ref);
                    },
                    tooltip: 'Add Floor',
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // 2. Floor Selector Toggle Row
              floorsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (floors) {
                  if (floors.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Text(
                        'No floors created yet. Click the + button above to add a floor.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 48.h,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: floors.map((f) {
                                return _buildSectionToggle(
                                  ref,
                                  f.id,
                                  f.name,
                                  activeFloorId == f.id,
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppTheme.error, size: 24),
                            onPressed: () {
                              if (activeFloorId != null) {
                                final activeFloor = floors.firstWhere((f) => f.id == activeFloorId);
                                _showDeleteFloorConfirm(context, ref, activeFloorId, activeFloor.name);
                              }
                            },
                            tooltip: 'Delete Active Floor',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16.h),

              // Legend indicators
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppTheme.surfaceContainerHigh),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(Colors.green, 'Vacant'),
                    _buildLegendItem(Colors.amber.shade600, 'Seated'),
                    _buildLegendItem(Colors.orange, 'Cooking'),
                    _buildLegendItem(Colors.blue, 'Dining'),
                    _buildLegendItem(Colors.purple, 'Bill'),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Interactive Floor Canvas
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppTheme.surfaceContainerHigh),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x02000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Stack(
                      children: [
                        // Blueprint grid paper background
                        Positioned.fill(
                          child: CustomPaint(painter: _FloorGridPainter()),
                        ),

                        // Draw tables relative positioning
                        Positioned.fill(
                          child: tablesAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(color: AppTheme.primary),
                            ),
                            error: (err, _) => Center(
                              child: Text('Error loading tables: $err'),
                            ),
                            data: (tables) {
                              final activeFloorTables = tables
                                  .where((t) => t.floorId == activeFloorId)
                                  .toList();

                              if (activeFloorTables.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No tables placed on this floor yet.\nDesign your floor in "Tables & QR" designer.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.secondary,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }

                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  final w = constraints.maxWidth;
                                  final h = constraints.maxHeight;

                                  return Stack(
                                    children: activeFloorTables.map((table) {
                                      final pos = tablePositions[table.id] ??
                                          NodePosition(x: 0.35, y: 0.35);
                                      final leftPos = pos.x * w;
                                      final topPos = pos.y * h;

                                      return Positioned(
                                        left: leftPos,
                                        top: topPos,
                                        child: _buildTableWidget(
                                          context,
                                          ref,
                                          table,
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        // FAB — only shown when floors exist AND there are tables on the active floor
                        floorsAsync.maybeWhen(
                          data: (floors) {
                            if (floors.isEmpty) return const SizedBox.shrink();
                            return tablesAsync.maybeWhen(
                              data: (tables) {
                                final activeFloorTables = tables
                                    .where((t) => t.floorId == activeFloorId)
                                    .toList();
                                if (activeFloorTables.isEmpty) return const SizedBox.shrink();
                                return Positioned(
                                  right: 20.w,
                                  bottom: 20.h,
                                  child: FloatingActionButton(
                                    onPressed: () {
                                      _showQuickSeatDialog(context, ref, tables);
                                    },
                                    backgroundColor: AppTheme.primary,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 24.r,
                                    ),
                                  ),
                                );
                              },
                              orElse: () => const SizedBox.shrink(),
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionToggle(
    WidgetRef ref,
    String floorId,
    String label,
    bool active,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(activeFloorIdProvider.notifier).state = floorId;
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: active ? AppTheme.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.sp,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? AppTheme.primary : AppTheme.secondary,
          ),
        ),
      ),
    );
  }

  void _showAddFloorDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Create New Floor',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16.sp,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Floor Name',
              hintText: 'e.g., Floor 2, Terrace, Rooftop',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  ref.read(floorsFutureProvider.notifier).addFloor(name);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Adding Floor "$name"...'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.teal,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Create',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteFloorConfirm(
    BuildContext context,
    WidgetRef ref,
    String floorId,
    String floorName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Delete Floor "$floorName"?',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16.sp,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$floorName"? All tables on this floor will lose their floor assignment.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              color: AppTheme.secondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(floorsFutureProvider.notifier).deleteFloor(floorId);
                ref.read(activeFloorIdProvider.notifier).state = null;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Deleting floor...'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.error,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6.w),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.secondary,
          ),
        ),
      ],
    );
  }

  // ── Table Element Builder ───────────────────────────────────────────────────
  Widget _buildTableWidget(
    BuildContext context,
    WidgetRef ref,
    TableDto table,
  ) {
    final statusMap = ref.watch(tableStatusProvider);
    final status = statusMap[table.id] ??
        TableStatusState(phase: TableDiningPhase.vacant, activeGuests: 0);
    final isRound = table.capacity == 2;

    final Color borderCol = switch (status.phase) {
      TableDiningPhase.vacant => Colors.green,
      TableDiningPhase.seated => Colors.amber.shade600,
      TableDiningPhase.cooking => Colors.orange,
      TableDiningPhase.dining => Colors.blue,
      TableDiningPhase.waitingForBill => Colors.purple,
    };

    final Color textCol = borderCol;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showTableDetailDrawer(context, ref, table);
        },
        borderRadius: BorderRadius.circular(isRound ? 99.r : 12.r),
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            shape: isRound ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isRound ? null : BorderRadius.circular(12.r),
            border: Border.all(color: borderCol, width: 2.w),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                table.tableNumber,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chair_rounded,
                    color: textCol.withValues(alpha: 0.8),
                    size: 12.r,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '${status.activeGuests}/${table.capacity}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: textCol,
                    ),
                  ),
                ],
              ),
              if (status.phase != TableDiningPhase.vacant) ...[
                SizedBox(height: 2.h),
                Text(
                  status.diningStatusDisplay,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w800,
                    color: textCol,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Seating Trigger Drawer ──────────────────────────────────────────────────
  void _showTableDetailDrawer(
    BuildContext context,
    WidgetRef ref,
    TableDto table,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final statusMap = ref.watch(tableStatusProvider);
            final status = statusMap[table.id] ??
                TableStatusState(
                  phase: TableDiningPhase.vacant,
                  activeGuests: 0,
                );

            final Color borderCol = switch (status.phase) {
              TableDiningPhase.vacant => Colors.green,
              TableDiningPhase.seated => Colors.amber.shade600,
              TableDiningPhase.cooking => Colors.orange,
              TableDiningPhase.dining => Colors.blue,
              TableDiningPhase.waitingForBill => Colors.purple,
            };

            return Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
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
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Table Details — ${table.tableNumber}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          Text(
                            'Capacity: ${table.capacity} Seating Seats',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: borderCol.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          status.phase.name.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: borderCol,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Divider(
                    height: 1.h,
                    thickness: 1.h,
                    color: AppTheme.surfaceContainerHigh,
                  ),
                  SizedBox(height: 16.h),

                  if (status.phase == TableDiningPhase.vacant) ...[
                    Text(
                      'Seat Guests (Manual Seating Trigger)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        _buildSeatButton(context, ref, table.id, 2),
                        SizedBox(width: 8.w),
                        _buildSeatButton(context, ref, table.id, 4),
                        SizedBox(width: 8.w),
                        if (table.capacity >= 6) ...[
                          _buildSeatButton(context, ref, table.id, 6),
                        ],
                      ],
                    ),
                  ] else ...[
                    _buildDetailRow(
                      Icons.timer_rounded,
                      'Session Duration',
                      status.sessionDurationDisplay,
                    ),
                    _buildDetailRow(
                      Icons.room_service_rounded,
                      'Dining Status',
                      status.diningStatusDisplay,
                    ),
                    _buildDetailRow(
                      Icons.people_rounded,
                      'Assigned Waiter',
                      status.waiterDisplay,
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        if (status.phase == TableDiningPhase.seated)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(tableStatusProvider.notifier)
                                    .updatePhase(table.id, TableDiningPhase.cooking);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Start Kitchen Preparation'),
                            ),
                          ),
                        if (status.phase == TableDiningPhase.cooking)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(tableStatusProvider.notifier)
                                    .updatePhase(table.id, TableDiningPhase.dining);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Mark Served'),
                            ),
                          ),
                        if (status.phase == TableDiningPhase.dining)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(tableStatusProvider.notifier)
                                    .updatePhase(table.id, TableDiningPhase.waitingForBill);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Request Bill'),
                            ),
                          ),
                        if (status.phase == TableDiningPhase.waitingForBill)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(tableStatusProvider.notifier)
                                    .updatePhase(table.id, TableDiningPhase.vacant);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Clear Table'),
                            ),
                          ),
                      ],
                    ),
                    if (status.phase != TableDiningPhase.waitingForBill) ...[
                      SizedBox(height: 8.h),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            ref
                                .read(tableStatusProvider.notifier)
                                .updatePhase(table.id, TableDiningPhase.vacant);
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: BorderSide(
                              color: AppTheme.error.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Text('Vacate Table'),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSeatButton(
    BuildContext context,
    WidgetRef ref,
    String tableId,
    int count,
  ) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          ref.read(tableStatusProvider.notifier).seatGuests(tableId, count);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Seated party of $count successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.teal,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Text('$count Guests'),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.secondary, size: 18.r),
          SizedBox(width: 12.w),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickSeatDialog(
    BuildContext context,
    WidgetRef ref,
    List<TableDto> tables,
  ) {
    final statusNotifier = ref.read(tableStatusProvider.notifier);
    final activeFloorId = ref.read(activeFloorIdProvider);

    final floorTables = tables
        .where((t) => t.floorId == activeFloorId)
        .toList();

    final vacant = floorTables.where((t) {
      final status = statusNotifier.getStatus(t.id);
      return status.phase == TableDiningPhase.vacant;
    }).toList();

    // Determine the correct empty state message
    final String? emptyMessage = vacant.isEmpty
        ? (floorTables.isEmpty
            ? 'No tables have been placed on this floor yet.\nGo to "Tables & QR" to design this floor.'
            : 'All tables on this floor are currently occupied!')
        : null;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Quick Manual Seating',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          content: emptyMessage != null
              ? Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    emptyMessage,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      color: AppTheme.secondary,
                    ),
                  ),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: vacant.length,
                    itemBuilder: (ctx, idx) {
                      final t = vacant[idx];
                      return ListTile(
                        leading: const Icon(
                          Icons.table_restaurant_rounded,
                          color: Colors.green,
                        ),
                        title: Text(
                          t.tableNumber,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'Capacity: ${t.capacity} seats',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            color: AppTheme.secondary,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.green,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          ref
                              .read(tableStatusProvider.notifier)
                              .seatGuests(t.id, t.capacity);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Seated at ${t.tableNumber} (${t.capacity} seats).',
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.teal,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FloorGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = AppTheme.secondaryContainer.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    const step = 20.0;

    // Draw vertical lines
    for (double x = 0; x < w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }

    // Draw horizontal lines
    for (double y = 0; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
