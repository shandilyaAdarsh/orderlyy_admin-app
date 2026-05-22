// lib/features/kitchen/presentation/screens/delayed_orders_feed_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../orders/domain/entities/order.dart';
import '../state/kitchen_queue_notifier.dart';

class DelayedOrdersFeedScreen extends ConsumerStatefulWidget {
  const DelayedOrdersFeedScreen({super.key});

  @override
  ConsumerState<DelayedOrdersFeedScreen> createState() => _DelayedOrdersFeedScreenState();
}

class _DelayedOrdersFeedScreenState extends ConsumerState<DelayedOrdersFeedScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTicketsAsync = ref.watch(kitchenQueueNotifierProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delayed KDS Tickets', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: activeTicketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('KDS System Error: $err')),
        data: (tickets) {
          // Delayed tickets are those in preparing/sent statuses for >15 minutes
          final delayedTickets = tickets.where((o) {
            final elapsed = DateTime.now().difference(o.createdAt).inMinutes;
            return (o.status == OrderStatus.sent || o.status == OrderStatus.preparing) && elapsed >= 15;
          }).toList();

          if (delayedTickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 80,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No delayed tickets in queue. Great job!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: delayedTickets.length,
            itemBuilder: (context, index) {
              final order = delayedTickets[index];
              final elapsedMinutes = DateTime.now().difference(order.createdAt).inMinutes;

              return Card(
                color: isDark ? AppColors.darkSurface : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.error, width: 2),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.error),
                              const SizedBox(width: 8),
                              Text(
                                'Table ${order.tableId}',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Delayed ${elapsedMinutes}m',
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Waiter: ${order.waiterName}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            'Status: ${order.status.name.toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.warning),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      ...order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 8, color: AppColors.error),
                              const SizedBox(width: 8),
                              Text(
                                '${item.quantity}x ${item.product.name} (${item.status.name})',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                foregroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Chime alert sent directly to Grill/Fryer coordinator.'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              },
                              child: const Text('Chime KDS Coordinator'),
                            ),
                          ),
                        ],
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
}
