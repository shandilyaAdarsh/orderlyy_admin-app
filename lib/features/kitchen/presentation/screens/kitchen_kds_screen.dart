// lib/features/kitchen/presentation/screens/kitchen_kds_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../orders/domain/entities/order_item.dart';
import '../state/kitchen_queue_notifier.dart';

class KitchenKdsScreen extends ConsumerWidget {
  const KitchenKdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTicketsAsync = ref.watch(kitchenQueueNotifierProvider);
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
      body: activeTicketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('KDS System Error: $err')),
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.success),
                  const SizedBox(height: 16),
                  Text(
                    'No active orders in preparation queue.',
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
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final order = tickets[index];

              // Calculate time elapsed
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
                      // Card Header
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

                      // Card Items list
                      Expanded(
                        child: ListView.builder(
                          itemCount: order.items.length,
                          itemBuilder: (context, iIndex) {
                            final item = order.items[iIndex];
                            
                            // Visual properties based on item preparation phase
                            final Color statusColor;
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
                                  // Quick Action button per item
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
      return const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20);
    } else {
      return const SizedBox.shrink();
    }
  }
}
