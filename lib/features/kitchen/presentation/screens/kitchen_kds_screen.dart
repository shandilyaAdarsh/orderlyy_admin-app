// lib/features/kitchen/presentation/screens/kitchen_kds_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../orders/domain/entities/order_item.dart';
import '../state/kitchen_queue_notifier.dart';

final selectedKdsStationProvider = StateProvider<String>((ref) => 'All');

class KitchenKdsScreen extends ConsumerWidget {
  const KitchenKdsScreen({super.key});

  String _getItemStation(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('burger') || cat.contains('main') || cat.contains('pizza') || cat.contains('pasta')) {
      return 'Hot Kitchen';
    }
    if (cat.contains('salad') || cat.contains('appetizer') || cat.contains('side') || cat.contains('cold')) {
      return 'Cold Kitchen';
    }
    if (cat.contains('dessert') || cat.contains('bakery') || cat.contains('sweet')) {
      return 'Dessert';
    }
    if (cat.contains('beverage') || cat.contains('drink') || cat.contains('bar') || cat.contains('juice')) {
      return 'Bar';
    }
    return 'Hot Kitchen';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTicketsAsync = ref.watch(kitchenQueueNotifierProvider);
    final selectedStation = ref.watch(selectedKdsStationProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitchen Display System (KDS)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(kitchenQueueNotifierProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Station filter chips
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', 'Hot Kitchen', 'Cold Kitchen', 'Dessert', 'Bar'].map((station) {
                final isSelected = selectedStation == station;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    selected: isSelected,
                    label: Text(station),
                    selectedColor: AppColors.primary,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(selectedKdsStationProvider.notifier).state = station;
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          // Queue tickets grid
          Expanded(
            child: activeTicketsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text('KDS System Error: $err')),
              data: (tickets) {
                // Filter items inside tickets, and filter out tickets with 0 remaining matching items
                final filteredTickets = tickets.map((order) {
                  final filteredItems = order.items.where((item) {
                    if (selectedStation == 'All') return true;
                    return _getItemStation(item.product.category) == selectedStation;
                  }).toList();
                  return order.copyWith(items: filteredItems);
                }).where((order) => order.items.isNotEmpty).toList();

                if (filteredTickets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.success),
                        const SizedBox(height: 16),
                        Text(
                          'No orders in $selectedStation queue.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisExtent: 380,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredTickets.length,
                  itemBuilder: (context, index) {
                    final order = filteredTickets[index];
                    final elapsedMinutes = DateTime.now().difference(order.createdAt).inMinutes;
                    final isDelayed = elapsedMinutes >= 15;

                    return Card(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDelayed ? AppColors.error : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isDelayed ? 2.0 : 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Table ${order.tableId}',
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDelayed ? AppColors.error.withValues(alpha: 0.1) : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${elapsedMinutes}m ago',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDelayed ? AppColors.error : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Expanded(
                              child: ListView.builder(
                                itemCount: order.items.length,
                                itemBuilder: (context, iIndex) {
                                  final item = order.items[iIndex];

                                  Color statusColor;
                                  switch (item.status) {
                                    case OrderItemStatus.queued:
                                      statusColor = AppColors.info;
                                      break;
                                    case OrderItemStatus.preparing:
                                      statusColor = AppColors.primary;
                                      break;
                                    case OrderItemStatus.ready:
                                      statusColor = AppColors.success;
                                      break;
                                    case OrderItemStatus.served:
                                      statusColor = Colors.grey;
                                      break;
                                    case OrderItemStatus.cancelled:
                                      statusColor = AppColors.error;
                                      break;
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${item.quantity}x',
                                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.product.name,
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  decoration: item.status == OrderItemStatus.cancelled ? TextDecoration.lineThrough : null,
                                                ),
                                              ),
                                              if (item.selectedModifiers.isNotEmpty)
                                                Text(
                                                  item.selectedModifiers.map((m) => m.name).join(', '),
                                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                                ),
                                            ],
                                          ),
                                        ),
                                        _buildItemActionButton(order.id, item, ref, theme),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemActionButton(String orderId, OrderItem item, WidgetRef ref, ThemeData theme) {
    if (item.status == OrderItemStatus.queued) {
      return TextButton(
        style: TextButton.styleFrom(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: Size.zero,
        ),
        onPressed: () {
          ref
              .read(kitchenQueueNotifierProvider.notifier)
              .updateItemStatus(orderId, item.id, OrderItemStatus.preparing);
        },
        child: const Text('Prep', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
      );
    } else if (item.status == OrderItemStatus.preparing) {
      return TextButton(
        style: TextButton.styleFrom(
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          foregroundColor: AppColors.success,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: Size.zero,
        ),
        onPressed: () {
          ref
              .read(kitchenQueueNotifierProvider.notifier)
              .updateItemStatus(orderId, item.id, OrderItemStatus.ready);
        },
        child: const Text('Ready', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
      );
    } else if (item.status == OrderItemStatus.ready) {
      return TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: Size.zero,
        ),
        onPressed: () {
          ref
              .read(kitchenQueueNotifierProvider.notifier)
              .updateItemStatus(orderId, item.id, OrderItemStatus.served);
        },
        child: const Text('Serve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
      );
    } else if (item.status == OrderItemStatus.served) {
      return const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20);
    } else {
      return const SizedBox.shrink();
    }
  }
}
