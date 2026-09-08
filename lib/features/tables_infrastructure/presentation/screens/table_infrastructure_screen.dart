import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/table_qr_file_save.dart';
import '../services/table_qr_png_service.dart';
import '../widgets/table_qr_bottom_sheet.dart';
import '../../data/dtos/table_dto.dart';
import '../../data/dtos/floor_dto.dart';
import '../../data/repositories/table_infrastructure_repository.dart';
import '../state/table_infrastructure_providers.dart';

// ── Local State & Interaction Providers ───────────────────────────────────────
enum EditorTool { select, drawZone, addLabel, multiSelect }

final selectedToolProvider = StateProvider<EditorTool>(
  (ref) => EditorTool.select,
);

// Table node layout positioning coordinates local state (mapped by table ID)
class NodePosition {
  final double x; // Percent (0.0 to 1.0)
  final double y; // Percent (0.0 to 1.0)
  final double angle; // Rotation in radians
  final bool isSelected;

  NodePosition({
    required this.x,
    required this.y,
    this.angle = 0.0,
    this.isSelected = false,
  });

  NodePosition copyWith({
    double? x,
    double? y,
    double? angle,
    bool? isSelected,
  }) {
    return NodePosition(
      x: x ?? this.x,
      y: y ?? this.y,
      angle: angle ?? this.angle,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

final tablePositionsProvider =
    StateNotifierProvider<TablePositionsNotifier, Map<String, NodePosition>>((
      ref,
    ) {
      return TablePositionsNotifier();
    });

class TablePositionsNotifier extends StateNotifier<Map<String, NodePosition>> {
  TablePositionsNotifier() : super({});

  void initialize(List<TableDto> tables) {
    final Map<String, NodePosition> updated = Map.from(state);
    bool changed = false;
    for (int i = 0; i < tables.length; i++) {
      final t = tables[i];
      if (!updated.containsKey(t.id)) {
        final row = i ~/ 3;
        final col = i % 3;
        updated[t.id] = NodePosition(x: 0.15 + (col * 0.2), y: 0.2 + (row * 0.2));
        changed = true;
      }
    }
    if (changed || state.isEmpty) {
      state = updated;
    }
  }

  void updatePosition(String id, double dx, double dy) {
    if (!state.containsKey(id)) return;
    state = {
      ...state,
      id: state[id]!.copyWith(
        x: (state[id]!.x + dx).clamp(0.02, 0.92),
        y: (state[id]!.y + dy).clamp(0.02, 0.88),
      ),
    };
  }

  void selectNode(String id) {
    state = state.map((key, val) {
      return MapEntry(key, val.copyWith(isSelected: key == id));
    });
  }

  void clearSelection() {
    state = state.map((key, val) {
      return MapEntry(key, val.copyWith(isSelected: false));
    });
  }

  void addPosition(String id, double x, double y) {
    state = {...state, id: NodePosition(x: x, y: y)};
  }
}

// Bulk QR PDF build checked set
final checkedQrTablesProvider = StateProvider<Set<String>>((ref) => {});
final tableSelectedFloorIdProvider = StateProvider<String?>((ref) => null);

// ── Screen Class ──────────────────────────────────────────────────────────────
class TableInfrastructureScreen extends ConsumerWidget {
  const TableInfrastructureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesFutureProvider);
    final selectedFloorId = ref.watch(tableSelectedFloorIdProvider);
    final floorsAsync = ref.watch(floorsFutureProvider);
    final tablePositions = ref.watch(tablePositionsProvider);
    final checkedTables = ref.watch(checkedQrTablesProvider);

    final desktop = MediaQuery.of(context).size.width >= 960;

    floorsAsync.whenData((floors) {
      if (selectedFloorId == null && floors.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(tableSelectedFloorIdProvider.notifier).state = floors.first.id;
        });
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Tables & QR',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 18.sp,
            ),
          ),
        ),
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Mass Builder trigger
          ElevatedButton.icon(
            onPressed: () {
              _showMassQrPanel(context, ref);
            },
            icon: Icon(
              Icons.qr_code_scanner_rounded,
              size: 16.r,
              color: Colors.white,
            ),
            label: Text(
              'Mass QR Builder',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 11.sp,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: Colors.white,
              minimumSize: Size(130.w, 36.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
          SizedBox(width: 16.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Divider(
            height: 1.h,
            thickness: 1.h,
            color: AppTheme.surfaceContainerHigh,
          ),
        ),
      ),
      body: tablesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error loading tables: $err',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
          ),
        ),
        data: (tables) {
          final filteredTables = tables.where((t) => t.floorId == selectedFloorId).toList();

          // Initialize default nodes position if empty
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(tablePositionsProvider.notifier).initialize(filteredTables);
            // Default select all tables for bulk builder
            if (checkedTables.isEmpty) {
              ref.read(checkedQrTablesProvider.notifier).state = filteredTables
                  .map((t) => t.id)
                  .toSet();
            }
          });

          return SafeArea(
            child: Row(
              children: [
                // 1. Sidebar Tools (Floor dropdown & Circle/Square shapes - desktop only)
                if (desktop) _buildSidebarTools(context, ref, selectedFloorId, floorsAsync),

                // 2. Gridded Vector Canvas
                Expanded(
                  child: Container(
                    color: AppTheme.surfaceContainerLow,
                    child: Column(
                      children: [
                        // Mobile Toolbar (Floor dropdown & Circle/Square shapes)
                        if (!desktop)
                          _buildMobileToolbar(context, ref, selectedFloorId, floorsAsync),

                        Expanded(
                          child: Stack(
                            children: [
                              // Grid background Custom Painter
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _BlueprintGridPainter(),
                                ),
                              ),

                              // Render drag-and-drop table nodes (Filtered to selected floor)
                              Positioned.fill(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final canvasWidth = constraints.maxWidth;
                                    final canvasHeight = constraints.maxHeight;

                                    return Stack(
                                      children: filteredTables.map((table) {
                                        final pos =
                                            tablePositions[table.id] ??
                                            NodePosition(x: 0.3, y: 0.3);

                                        final pixelX = pos.x * canvasWidth;
                                        final pixelY = pos.y * canvasHeight;

                                        return Positioned(
                                          left: pixelX,
                                          top: pixelY,
                                          child: _buildDraggableTableNode(
                                            context,
                                            ref,
                                            table,
                                            pos,
                                            canvasWidth,
                                            canvasHeight,
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ),

                              // Zoom indicator controls overlay
                              Positioned(
                                right: 16.w,
                                bottom: 16.h,
                                child: _buildZoomControls(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Vector Tools Layouts ────────────────────────────────────────────────────
  Widget _buildSidebarTools(
    BuildContext context,
    WidgetRef ref,
    String? selectedFloorId,
    AsyncValue<List<FloorDto>> floorsAsync,
  ) {
    return Container(
      width: 260.w,
      height: double.infinity,
      color: AppTheme.surfaceContainerLowest,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Active Floor',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          floorsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error loading floors: $err'),
            data: (floors) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedFloorId,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    items: floors.map((f) {
                      return DropdownMenuItem<String>(
                        value: f.id,
                        child: Text(
                          f.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      ref.read(tableSelectedFloorIdProvider.notifier).state = val;
                    },
                    hint: const Text('Choose a Floor'),
                  ),
                  SizedBox(height: 8.h),
                  ElevatedButton.icon(
                    onPressed: () => _showAddFloorDialog(context, ref),
                    icon: Icon(Icons.add_rounded, size: 16.r),
                    label: Text(
                      'Create Floor',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.sp, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceContainerLow,
                      foregroundColor: AppTheme.primary,
                      elevation: 0,
                      side: const BorderSide(color: AppTheme.surfaceContainerHigh),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 24.h),
          Divider(height: 1.h, color: AppTheme.surfaceContainerHigh),
          SizedBox(height: 20.h),

          Text(
            'Tables Library',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Click a box below to add a table to the active floor:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.sp,
              color: AppTheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12.h),

          // Draggable library shapes grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              childAspectRatio: 1.1,
              children: [
                _buildLibraryShapeCard(
                  context,
                  ref,
                  'Circle Box',
                  Icons.circle_outlined,
                  selectedFloorId,
                ),
                _buildLibraryShapeCard(
                  context,
                  ref,
                  'Square Box',
                  Icons.crop_din_rounded,
                  selectedFloorId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileToolbar(
    BuildContext context,
    WidgetRef ref,
    String? selectedFloorId,
    AsyncValue<List<FloorDto>> floorsAsync,
  ) {
    return Container(
      height: 56.h,
      color: AppTheme.surfaceContainerLowest,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      child: Row(
        children: [
          Expanded(
            child: floorsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (floors) {
                return DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedFloorId,
                    isExpanded: true,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    items: floors.map((f) {
                      return DropdownMenuItem<String>(
                        value: f.id,
                        child: Text(f.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      ref.read(tableSelectedFloorIdProvider.notifier).state = val;
                    },
                    hint: const Text('Select Floor'),
                  ),
                );
              },
            ),
          ),
          VerticalDivider(
            width: 16.w,
            thickness: 1.w,
            color: AppTheme.surfaceContainerHigh,
          ),
          _buildMobileShapeTextBtn(context, ref, 'Circle Box', selectedFloorId),
          SizedBox(width: 8.w),
          _buildMobileShapeTextBtn(context, ref, 'Square Box', selectedFloorId),
        ],
      ),
    );
  }

  Widget _buildMobileShapeTextBtn(
    BuildContext context,
    WidgetRef ref,
    String text,
    String? selectedFloorId,
  ) {
    return ElevatedButton(
      onPressed: () => _addLibraryTable(context, ref, text, selectedFloorId),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.surfaceContainerLowest,
        foregroundColor: AppTheme.onSurface,
        elevation: 0,
        minimumSize: Size(80.w, 36.h),
        side: const BorderSide(color: AppTheme.surfaceContainerHigh),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildLibraryShapeCard(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
    String? selectedFloorId,
  ) {
    return InkWell(
      onTap: () {
        _addLibraryTable(context, ref, label, selectedFloorId);
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.secondary, size: 24.r),
            SizedBox(height: 6.h),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                color: AppTheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addLibraryTable(BuildContext context, WidgetRef ref, String shapeType, String? floorId) {
    if (floorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or create a Floor first before adding tables.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    final existingTables = ref.read(tablesFutureProvider).value ?? [];
    final nextNum = existingTables.length + 1;
    final defaultLabel = 'Table $nextNum';
    final defaultCapacity = shapeType.contains('Circle') ? 2 : 4;

    _showAddTableDialog(context, ref, defaultLabel, defaultCapacity, floorId, shapeType);
  }

  void _showAddTableDialog(
    BuildContext context,
    WidgetRef ref,
    String defaultLabel,
    int defaultCapacity,
    String floorId,
    String shapeType,
  ) {
    final nameController = TextEditingController(text: defaultLabel);
    final capacityController = TextEditingController(text: defaultCapacity.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Add $shapeType Table',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        errorMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Table Number / Name',
                      hintText: 'e.g., Table 5, T1, VIP',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Capacity (Seats)',
                      hintText: 'e.g., 2, 4, 6',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final label = nameController.text.trim();
                          final capacityStr = capacityController.text.trim();
                          final capacity = int.tryParse(capacityStr) ?? defaultCapacity;

                          if (label.isEmpty) {
                            setState(() => errorMessage = 'Table Name cannot be empty.');
                            return;
                          }

                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          try {
                            await ref
                                .read(tablesFutureProvider.notifier)
                                .addTable(label, capacity, floorId: floorId);
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Table "$label" added successfully.'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.teal,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() {
                                isLoading = false;
                                if (e is ApiException) {
                                  errorMessage = e.message;
                                } else {
                                  errorMessage = e.toString().replaceAll('Exception: ', '');
                                }
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Create',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            );
          },
        );
      },
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
                  ref.read(floorsFutureProvider.notifier).addFloor(name).then((_) {
                    final floors = ref.read(floorsFutureProvider).value;
                    if (floors != null && floors.isNotEmpty) {
                      final newFloor = floors.firstWhere(
                        (f) => f.name.toLowerCase() == name.toLowerCase(),
                        orElse: () => floors.last,
                      );
                      ref.read(tableSelectedFloorIdProvider.notifier).state = newFloor.id;
                    }
                  });
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

  void _showDeleteTableConfirm(
    BuildContext context,
    WidgetRef ref,
    TableDto table,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Table?',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          content: Text(
            'Are you sure you want to delete Table ${table.tableNumber}?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
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
                ref.read(tablesFutureProvider.notifier).deleteTable(table.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Table ${table.tableNumber} deleted.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.error,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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



  // ── Draggable Table Node Builder ────────────────────────────────────────────
  Widget _buildDraggableTableNode(
    BuildContext context,
    WidgetRef ref,
    TableDto table,
    NodePosition pos,
    double canvasWidth,
    double canvasHeight,
  ) {
    final isRound = table.tableNumber.contains('L') || table.capacity == 2;
    final size = pos.isSelected ? 100.r : 90.r;

    return GestureDetector(
      onPanUpdate: (details) {
        // Drag update relative to canvas size
        final dx = details.delta.dx / canvasWidth;
        final dy = details.delta.dy / canvasHeight;
        ref
            .read(tablePositionsProvider.notifier)
            .updatePosition(table.id, dx, dy);
      },
      onTap: () => _showTableQrSheet(context, ref, table),
      onLongPress: () {
        ref.read(tablePositionsProvider.notifier).selectNode(table.id);
      },
      child: Transform.rotate(
        angle: pos.angle,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: pos.isSelected
                ? AppTheme.primaryContainer.withValues(alpha: 0.08)
                : AppTheme.surfaceContainerLowest,
            shape: isRound ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isRound ? null : BorderRadius.circular(8.r),
            border: Border.all(
              color: pos.isSelected ? AppTheme.primary : AppTheme.secondary,
              width: pos.isSelected ? 2.5.w : 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: pos.isSelected
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: pos.isSelected ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Table label DTO name
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    table.tableNumber,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: pos.isSelected
                          ? AppTheme.primary
                          : AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    'Cap: ${table.capacity}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),

              // Checked Badge (if selected for bulk QR builder)
              if (ref.watch(checkedQrTablesProvider).contains(table.id))
                Positioned(
                  top: -6.h,
                  left: -6.w,
                  child: Container(
                    width: 20.r,
                    height: 20.r,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 12.r),
                  ),
                ),

              // Selection border handles (only when selected)
              if (pos.isSelected) ...[
                Positioned(top: -4.h, left: -4.w, child: _buildHandleDot()),
                Positioned(top: -4.h, right: -4.w, child: _buildHandleDot()),
                Positioned(bottom: -4.h, left: -4.w, child: _buildHandleDot()),
                Positioned(bottom: -4.h, right: -4.w, child: _buildHandleDot()),
                Positioned(
                  top: -16.h,
                  right: -16.w,
                  child: GestureDetector(
                    onTap: () => _showDeleteTableConfirm(context, ref, table),
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 14.r,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandleDot() {
    return Container(
      width: 8.r,
      height: 8.r,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary, width: 2.w),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove, size: 16.r, color: AppTheme.secondary),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            onPressed: () {},
          ),
          SizedBox(width: 8.w),
          Text(
            '100%',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            icon: Icon(Icons.add, size: 16.r, color: AppTheme.secondary),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── Mass QR Builder Bottom Sheet ────────────────────────────────────────────
  void _showMassQrPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _MassQrBuilderPanel();
      },
    );
  }

  void _showTableQrSheet(BuildContext context, WidgetRef ref, TableDto table) {
    final floors = ref.read(floorsFutureProvider).value ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TableQrBottomSheet(
        table: table,
        floorName: floorNameForTable(table, floors),
      ),
    );
  }
}

class _MassQrBuilderPanel extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MassQrBuilderPanel> createState() =>
      _MassQrBuilderPanelState();
}

class _MassQrBuilderPanelState extends ConsumerState<_MassQrBuilderPanel> {
  bool _isBuilding = false;
  final _pngService = TableQrPngService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tables = ref.read(tablesFutureProvider).value;
      if (tables != null && ref.read(checkedQrTablesProvider).isEmpty) {
        ref.read(checkedQrTablesProvider.notifier).state =
            tables.map((t) => t.id).toSet();
      }
    });
  }

  Future<void> _downloadZip(
    List<TableDto> allTables,
    Set<String> selectedIds,
  ) async {
    setState(() => _isBuilding = true);
    try {
      final repo = ref.read(tableInfrastructureRepositoryProvider);
      final floors = ref.read(floorsFutureProvider).value ?? [];
      final floorNames = {for (final f in floors) f.id: f.name};

      final selected = allTables.where((t) => selectedIds.contains(t.id)).toList();

      Future<String> resolveUrl(TableDto table) async {
        if (table.qrUrl != null && table.qrUrl!.isNotEmpty) {
          return table.qrUrl!;
        }
        final updated = await repo.generateQr(table.id);
        return updated.qrUrl ?? '';
      }

      final zipBytes = await _pngService.buildZipArchive(
        tables: selected,
        floorNamesById: floorNames,
        resolveQrUrl: resolveUrl,
      );

      await saveBytesAsDownload(zipBytes, 'orderlyy-qr-codes.zip');
      ref.invalidate(tablesFutureProvider);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded ${selected.length} QR codes as ZIP'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ZIP export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBuilding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesFutureProvider);
    final checkedSet = ref.watch(checkedQrTablesProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      child: tablesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (err, _) => Text('Error loading: $err'),
        data: (tables) {
          return Column(
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppTheme.primary,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Mass QR Builder',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20.r,
                      color: AppTheme.secondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Select tables and download PNG QR codes in a single ZIP file.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16.h),

              // Build sequence overlay or listing
              if (_isBuilding) ...[
                Container(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  width: double.infinity,
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppTheme.primary),
                      SizedBox(height: 12.h),
                      Text(
                        'Building QR ZIP...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      const LinearProgressIndicator(color: AppTheme.primary),
                    ],
                  ),
                ),
              ] else ...[
                // Tables checklist
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 200.h),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: tables.length,
                    separatorBuilder: (context, idx) => SizedBox(height: 6.h),
                    itemBuilder: (context, idx) {
                      final t = tables[idx];
                      final isChecked = checkedSet.contains(t.id);

                      return GestureDetector(
                        onTap: () {
                          final next = Set<String>.from(checkedSet);
                          if (isChecked) {
                            next.remove(t.id);
                          } else {
                            next.add(t.id);
                          }
                          ref.read(checkedQrTablesProvider.notifier).state =
                              next;
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: isChecked
                                ? AppTheme.primaryContainer.withValues(
                                    alpha: 0.04,
                                  )
                                : AppTheme.background,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isChecked
                                  ? AppTheme.primary
                                  : AppTheme.surfaceContainerHigh,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isChecked
                                    ? Icons.check_box_rounded
                                    : Icons.check_box_outline_blank_rounded,
                                color: isChecked
                                    ? AppTheme.primary
                                    : AppTheme.secondary,
                                size: 20.r,
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'Section: ${t.sectionId} • Table ${t.tableNumber}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                isChecked ? 'Included' : 'Excluded',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.sp,
                                  color: isChecked
                                      ? AppTheme.primary
                                      : AppTheme.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20.h),

                // Trigger generation button
                ElevatedButton(
                  onPressed: checkedSet.isEmpty || _isBuilding
                      ? null
                      : () => _downloadZip(tables, checkedSet),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    disabledBackgroundColor: AppTheme.surfaceContainerHigh,
                  ),
                  child: Text('Download all as ZIP (${checkedSet.length})'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Blueprint Custom Painter ─────────────────────────────────────────────────
class _BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = AppTheme.secondaryContainer.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    const step = 40.0;

    // Draw vertical grid lines
    for (double x = 0; x < w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }

    // Draw horizontal grid lines
    for (double y = 0; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
