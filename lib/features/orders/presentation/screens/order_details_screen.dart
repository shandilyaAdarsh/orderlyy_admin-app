// lib/features/orders/presentation/screens/order_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_status.dart';
import '../../data/providers/orders_repository_providers.dart';
import '../../../../shared/models/result.dart';
import '../../../../shared/models/failures.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(ordersRepositoryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<Result<Order, AppFailure>>(
      stream: repository.watchOrder(orderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final result = snapshot.data;
        if (result == null || result is Failure<Order, AppFailure>) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order Details')),
            body: const Center(
              child: Text('Order not found or has been completed.'),
            ),
          );
        }

        final order = (result as Success<Order, AppFailure>).value;

        return Scaffold(
          appBar: AppBar(
            title: Text('Table ${order.tableId} Details'),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.circle,
                      color: AppColors.success,
                      size: 10,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'KDS Synced',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressTimeline(order, theme, isDark),
                const SizedBox(height: 16),
                _buildWaiterOwnershipCard(context, ref, order, theme, isDark),
                const SizedBox(height: 16),
                _buildItemsList(context, ref, order, theme, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressTimeline(Order order, ThemeData theme, bool isDark) {
    final stages = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.served,
    ];

    final currentStageIndex = stages.indexOf(order.status);

    return Card(
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Flow Stage',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(stages.length, (index) {
                final stage = stages[index];
                final isCompleted = index <= currentStageIndex;
                final isActive = index == currentStageIndex;
                final label = stage.name.toUpperCase();

                Color circleColor = Colors.grey[300]!;
                Color labelColor = Colors.grey[600]!;
                if (isCompleted) {
                  circleColor = AppColors.primary;
                  labelColor = AppColors.primary;
                }
                if (isActive) {
                  circleColor = AppColors.secondary;
                  labelColor = AppColors.secondary;
                }

                return Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 2,
                              color: index == 0
                                  ? Colors.transparent
                                  : (index <= currentStageIndex
                                        ? AppColors.primary
                                        : Colors.grey[300]),
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: circleColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isActive
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: isCompleted && !isActive
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isCompleted
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 2,
                              color: index == stages.length - 1
                                  ? Colors.transparent
                                  : (index < currentStageIndex
                                        ? AppColors.primary
                                        : Colors.grey[300]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: labelColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaiterOwnershipCard(
    BuildContext context,
    WidgetRef ref,
    Order order,
    ThemeData theme,
    bool isDark,
  ) {
    return Card(
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: const Icon(Icons.person_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waiter Ownership',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.staffName ?? 'Unknown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(
    BuildContext context,
    WidgetRef ref,
    Order order,
    ThemeData theme,
    bool isDark,
  ) {
    return Card(
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Items',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  order.totalAmount.format(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (order.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: Text('No items in this order.')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item.menuItemName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      item.notes ?? '',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Text(
                      '${item.quantity}x ${(item.unitPrice * item.quantity).format()}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }


}
