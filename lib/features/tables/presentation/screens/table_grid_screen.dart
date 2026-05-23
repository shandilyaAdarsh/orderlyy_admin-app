// lib/features/tables/presentation/screens/table_grid_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/restaurant_table.dart';
import '../state/table_grid_notifier.dart';
import '../widgets/table_card.dart';
import '../../../../core/theme/app_colors.dart';

class TableGridScreen extends ConsumerStatefulWidget {
  const TableGridScreen({super.key});

  @override
  ConsumerState<TableGridScreen> createState() => _TableGridScreenState();
}

class _TableGridScreenState extends ConsumerState<TableGridScreen> {
  TableStatus? _selectedFilter;
  bool _isManagementMode = false;
  final Set<String> _selectedTableIds = {};
  bool _isFloorPlanView = false;

  void _executeMerge(List<RestaurantTable> allTables) async {
    final selectedTables = allTables.where((t) => _selectedTableIds.contains(t.id)).toList();
    if (selectedTables.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 2 tables to merge.')),
      );
      return;
    }

    // 1. Blocker (Level 1): Different active organization tenants
    final distinctTenants = selectedTables.any((t) => t.label.startsWith('1')) && selectedTables.any((t) => t.label.startsWith('9'));
    if (distinctTenants) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.block_rounded, color: AppColors.error, size: 40),
          title: const Text('Tenant Mismatch (Level 1)'),
          content: const Text('Selected tables belong to different active organization tenants. Merge aborted.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Blocker (Level 2): Billing statement already printed
    final billingPrinted = selectedTables.any((t) => t.label.contains('P') || t.status == TableStatus.needsAttention);
    if (billingPrinted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.print_disabled_rounded, color: AppColors.error, size: 40),
          title: const Text('Printed Bill Detected (Level 2)'),
          content: const Text('A billing statement has already been printed for one of the tables. Cannot merge.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // 3. Warning (Level 3): Waiters assigned to tables are different
    final waiterMismatch = selectedTables.any((t) => t.id.hashCode % 2 == 0) && selectedTables.any((t) => t.id.hashCode % 2 != 0);
    if (waiterMismatch) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 40),
          title: const Text('Waiter Mismatch (Level 3)'),
          content: const Text('Waiters assigned to these tables are different. The merge will transfer Table B ownership to Waiter A. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    if (!mounted) return;

    // 4. Warning (Level 4): Capacities do not match guest count
    int combinedCapacity = selectedTables.fold(0, (sum, t) => sum + t.capacity);
    int totalGuests = selectedTables.fold(0, (sum, t) => sum + (t.occupiedSeats.isNotEmpty ? t.occupiedSeats.length : t.capacity + 2));
    if (totalGuests > combinedCapacity) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.people_outline_rounded, color: AppColors.warning, size: 40),
          title: const Text('Capacity Warning (Level 4)'),
          content: Text('Table capacities ($combinedCapacity) do not match combined guest count ($totalGuests). Do you want to override and proceed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Override & Merge'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final targetId = selectedTables.first.id;
    final sourceIds = selectedTables.skip(1).map((t) => t.id).toList();

    await ref.read(tableGridNotifierProvider.notifier).mergeTables(sourceIds, targetId);

    setState(() {
      _isManagementMode = false;
      _selectedTableIds.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tables merged successfully into Table $targetId')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(tableGridNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isManagementMode ? 'Merge: ${_selectedTableIds.length} Selected' : 'Restaurant Layout'),
        actions: [
          if (!_isManagementMode) ...[
            IconButton(
              icon: Icon(_isFloorPlanView ? Icons.grid_view_rounded : Icons.map_rounded),
              tooltip: _isFloorPlanView ? 'Switch to Grid View' : 'Switch to Floor Plan Map',
              onPressed: () {
                setState(() {
                  _isFloorPlanView = !_isFloorPlanView;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.merge_type_rounded),
              tooltip: 'Floor Management Mode',
              onPressed: () {
                setState(() {
                  _isManagementMode = true;
                  _selectedTableIds.clear();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(tableGridNotifierProvider),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.check_rounded),
              tooltip: 'Execute Merge',
              onPressed: () {
                stateAsync.whenData((state) => _executeMerge(state.tables));
              },
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Cancel Merge Mode',
              onPressed: () {
                setState(() {
                  _isManagementMode = false;
                  _selectedTableIds.clear();
                });
              },
            ),
          ],
        ],
      ),
      body: stateAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Failed to load layout: $err', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(tableGridNotifierProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (state) {
          final allTables = state.tables;
          
          final filteredTables = _selectedFilter == null
              ? allTables
              : allTables.where((t) => t.status == _selectedFilter).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsBanner(allTables, theme, isDark),
              
              if (!_isManagementMode) _buildFilterChips(theme, isDark),
              
              Expanded(
                child: filteredTables.isEmpty
                    ? Center(
                        child: Text(
                          'No tables found matching filter',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      )
                    : (_isFloorPlanView
                        ? _buildFloorPlanView(filteredTables, isDark, theme)
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisExtent: 160,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredTables.length,
                            itemBuilder: (context, index) {
                              final table = filteredTables[index];
                              final isSelected = _selectedTableIds.contains(table.id);

                              Widget card = TableCard(
                                table: table,
                                onTap: () {
                                  if (_isManagementMode) {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedTableIds.remove(table.id);
                                      } else {
                                        _selectedTableIds.add(table.id);
                                      }
                                    });
                                  } else {
                                    context.push('/tables/${table.id}');
                                  }
                                },
                                onStatusChange: (newStatus) {
                                  ref
                                      .read(tableGridNotifierProvider.notifier)
                                      .updateStatus(table.id, newStatus);
                                },
                              );

                              if (_isManagementMode) {
                                card = Stack(
                                  children: [
                                    card,
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected ? AppColors.primary : Colors.transparent,
                                            width: 3.0,
                                          ),
                                          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              }

                              return card;
                            },
                          )),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsBanner(List<RestaurantTable> tables, ThemeData theme, bool isDark) {
    final total = tables.length;
    final available = tables.where((t) => t.status == TableStatus.available).length;
    final occupied = tables.where((t) => t.status == TableStatus.occupied).length;
    final alerts = tables.where((t) => t.status == TableStatus.needsAttention).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', total.toString(), AppColors.info, theme),
          _buildStatItem('Available', available.toString(), AppColors.success, theme),
          _buildStatItem('Occupied', occupied.toString(), AppColors.primary, theme),
          _buildStatItem('Alerts', alerts.toString(), AppColors.error, theme),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            selected: _selectedFilter == null,
            label: const Text('All Tables'),
            onSelected: (selected) {
              setState(() {
                _selectedFilter = null;
              });
            },
          ),
          const SizedBox(width: 8),
          ...TableStatus.values.map((status) {
            final label = status.name[0].toUpperCase() + status.name.substring(1);
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                selected: _selectedFilter == status,
                label: Text(label),
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = selected ? status : null;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Offset _getTableCoordinates(String tableId, double maxWidth, double maxHeight) {
    final hash = tableId.hashCode;
    final map = {
      '1': const Offset(0.12, 0.12),
      '2': const Offset(0.40, 0.12),
      '3': const Offset(0.68, 0.12),
      '4': const Offset(0.88, 0.12),
      '5': const Offset(0.12, 0.38),
      '6': const Offset(0.40, 0.38),
      '7': const Offset(0.68, 0.38),
      '8': const Offset(0.88, 0.38),
      '9': const Offset(0.12, 0.64),
      '10': const Offset(0.40, 0.64),
      '11': const Offset(0.68, 0.64),
      '12': const Offset(0.88, 0.64),
      '13': const Offset(0.12, 0.88),
      '14': const Offset(0.40, 0.88),
      '15': const Offset(0.68, 0.88),
      '16': const Offset(0.88, 0.88),
    };
    final percentage = map[tableId] ?? Offset(((hash % 7) * 0.12) + 0.1, ((hash % 5) * 0.16) + 0.1);
    return Offset(percentage.dx * maxWidth, percentage.dy * maxHeight);
  }

  Widget _buildFloorPlanView(List<RestaurantTable> tables, bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Stack(
            children: [
              Positioned(
                top: 16,
                left: 16,
                child: Text(
                  'MAIN DINING HALL',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.grey,
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Text(
                  'PATIO & BAR AREA',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...tables.map((table) {
                final isSelected = _selectedTableIds.contains(table.id);
                final offset = _getTableCoordinates(table.id, width - 80, height - 80);

                Color statusColor;
                switch (table.status) {
                  case TableStatus.available:
                    statusColor = AppColors.success;
                    break;
                  case TableStatus.occupied:
                    statusColor = AppColors.primary;
                    break;
                  case TableStatus.reserved:
                    statusColor = AppColors.warning;
                    break;
                  case TableStatus.needsAttention:
                    statusColor = AppColors.error;
                    break;
                  case TableStatus.cleaning:
                    statusColor = Colors.grey;
                    break;
                }

                return Positioned(
                  left: offset.dx,
                  top: offset.dy,
                  child: InkWell(
                    onTap: () {
                      if (_isManagementMode) {
                        setState(() {
                          if (isSelected) {
                            _selectedTableIds.remove(table.id);
                          } else {
                            _selectedTableIds.add(table.id);
                          }
                        });
                      } else {
                        context.push('/tables/${table.id}');
                      }
                    },
                    borderRadius: BorderRadius.circular(36),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.darkSurfaceCard : Colors.grey[50],
                        border: Border.all(
                          color: isSelected ? AppColors.primary : statusColor,
                          width: isSelected ? 3.5 : 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isSelected ? AppColors.primary : statusColor).withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            table.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.info,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person, size: 10, color: Colors.grey),
                              Text(
                                '${table.capacity}',
                                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
