// lib/features/tables/presentation/screens/table_split_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/money.dart';
import '../../../orders/presentation/state/active_order_notifier.dart';
import '../../../orders/domain/entities/order_item.dart';
import '../../providers/tables_providers.dart';

class TableSplitScreen extends ConsumerStatefulWidget {
  final String tableId;

  const TableSplitScreen({
    super.key,
    required this.tableId,
  });

  @override
  ConsumerState<TableSplitScreen> createState() => _TableSplitScreenState();
}

class _TableSplitScreenState extends ConsumerState<TableSplitScreen> {
  // Map from item ID to assigned seat number (1 to 6)
  final Map<String, int> _itemSeatAssignments = {};
  
  // Custom names for seats
  final Map<int, String> _seatNames = {
    1: 'Guest 1',
    2: 'Guest 2',
    3: 'Guest 3',
    4: 'Guest 4',
    5: 'Guest 5',
    6: 'Guest 6',
  };

  @override
  Widget build(BuildContext context) {
    final activeOrderAsync = ref.watch(activeOrderNotifierProvider(widget.tableId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Split Table ${widget.tableId} Sessions'),
      ),
      body: activeOrderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error loading session: $err')),
        data: (order) {
          if (order == null || order.items.isEmpty) {
            return const Center(
              child: Text('No active items to split.'),
            );
          }

          // Initialize default assignments to seat 1 if not assigned yet
          for (final item in order.items) {
            _itemSeatAssignments.putIfAbsent(item.id, () => 1);
          }

          // Group items by assigned seat
          final Map<int, List<OrderItem>> seatGroupedItems = {};
          for (int seatNum = 1; seatNum <= 6; seatNum++) {
            seatGroupedItems[seatNum] = [];
          }
          for (final item in order.items) {
            final assignedSeat = _itemSeatAssignments[item.id] ?? 1;
            seatGroupedItems[assignedSeat]?.add(item);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 700;

              final bodyWidget = Column(
                children: [
                  Expanded(
                    child: isTablet
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: list of all items & assignment controls
                              Expanded(
                                flex: 4,
                                child: _buildItemsListCard(order.items, theme, isDark),
                              ),
                              const SizedBox(width: 16),
                              // Right: 6 partitions view
                              Expanded(
                                flex: 5,
                                child: _buildSeatsGrid(seatGroupedItems, theme, isDark),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(
                                flex: 4,
                                child: _buildItemsListCard(order.items, theme, isDark),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                flex: 5,
                                child: _buildSeatsGrid(seatGroupedItems, theme, isDark),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  _buildBottomActionBar(order.items),
                ],
              );

              return Padding(
                padding: const EdgeInsets.all(16.0),
                key: const ValueKey('split-layout-root'),
                child: bodyWidget,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildItemsListCard(List<OrderItem> items, ThemeData theme, bool isDark) {
    return Card(
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final currentSeat = _itemSeatAssignments[item.id] ?? 1;

                  return Card(
                    color: isDark ? AppColors.darkSurfaceCard : Colors.grey[50],
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              '${item.quantity}x',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(item.totalPrice.formatted, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          DropdownButton<int>(
                            value: currentSeat,
                            items: List.generate(6, (i) => i + 1)
                                .map((seatNum) => DropdownMenuItem(
                                      value: seatNum,
                                      child: Text('Seat $seatNum'),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _itemSeatAssignments[item.id] = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatsGrid(Map<int, List<OrderItem>> seatGroupedItems, ThemeData theme, bool isDark) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 180,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        final seatNum = index + 1;
        final seatItems = seatGroupedItems[seatNum] ?? [];
        
        // Calculate subtotal
        var seatSubtotal = const Money(amountInCents: 0);
        for (final item in seatItems) {
          if (item.status != OrderItemStatus.cancelled) {
            seatSubtotal = seatSubtotal + item.totalPrice;
          }
        }

        return Card(
          color: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: seatItems.isNotEmpty ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: seatItems.isNotEmpty ? 1.5 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _seatNames[seatNum]!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (seatItems.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${seatItems.length} items',
                          style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: seatItems.isEmpty
                      ? Center(
                          child: Text(
                            'Empty seat',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: seatItems.length,
                          itemBuilder: (context, iIndex) {
                            final item = seatItems[iIndex];
                            return Text(
                              '${item.quantity}x ${item.product.name}',
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(seatSubtotal.formatted, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActionBar(List<OrderItem> items) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.call_split_rounded),
            label: const Text('Execute Partition & Notify KDS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () async {
              // Prepare partitions payload
              final partitions = <Map<String, dynamic>>[];
              for (int seatNum = 1; seatNum <= 6; seatNum++) {
                final seatItemIds = items
                    .where((item) => (_itemSeatAssignments[item.id] ?? 1) == seatNum)
                    .map((item) => item.id)
                    .toList();

                if (seatItemIds.isNotEmpty) {
                  partitions.add({
                    'seat_number': seatNum,
                    'guest_name': _seatNames[seatNum],
                    'ordered_item_ids': seatItemIds,
                  });
                }
              }

              if (partitions.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please assign at least one item.')),
                );
                return;
              }

              // Execute optimistic split
              await ref.read(tablesRepositoryProvider).splitTable(widget.tableId, partitions);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Table split successfully. KDS notified.')),
                );
                context.pop();
              }
            },
          ),
        ),
      ],
    );
  }
}
