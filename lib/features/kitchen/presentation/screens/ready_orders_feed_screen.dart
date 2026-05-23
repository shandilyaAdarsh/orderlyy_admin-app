// lib/features/kitchen/presentation/screens/ready_orders_feed_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/providers/orders_providers.dart';
import '../state/kitchen_queue_notifier.dart';

class ReadyOrdersFeedScreen extends ConsumerStatefulWidget {
  const ReadyOrdersFeedScreen({super.key});

  @override
  ConsumerState<ReadyOrdersFeedScreen> createState() => _ReadyOrdersFeedScreenState();
}

class _ReadyOrdersFeedScreenState extends ConsumerState<ReadyOrdersFeedScreen> {
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
        title: const Text('Ready for Delivery', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: activeTicketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('KDS System Error: $err')),
        data: (tickets) {
          final readyTickets = tickets.where((o) => o.status == OrderStatus.ready).toList();

          if (readyTickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delivery_dining_rounded,
                    size: 80,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders ready for pickup.',
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
            itemCount: readyTickets.length,
            itemBuilder: (context, index) {
              final order = readyTickets[index];
              final elapsed = DateTime.now().difference(order.updatedAt);
              final isPickupDelayed = elapsed.inMinutes >= 5;

              final borderAccent = isPickupDelayed ? AppColors.error : AppColors.success;

              return Card(
                color: isDark ? AppColors.darkSurface : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isPickupDelayed ? AppColors.error : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: isPickupDelayed ? 2 : 1,
                  ),
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
                              Container(
                                width: 8,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: borderAccent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
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
                              color: borderAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Ready ${elapsed.inMinutes}m ago',
                              style: TextStyle(
                                color: borderAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Assigned Waiter: ${order.waiterName}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Divider(height: 20),
                      ...order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.check_rounded, color: AppColors.success, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                '${item.quantity}x ${item.product.name}',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.hail_rounded),
                          label: const Text('Confirm Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            await HapticFeedback.lightImpact();
                            
                            // To complete, save order with OrderStatus.completed
                            final ordersRepo = ref.read(ordersRepositoryProvider);
                            final updated = order.copyWith(
                              status: OrderStatus.completed,
                              updatedAt: DateTime.now(),
                            );
                            await ordersRepo.saveOrder(updated);
                            
                            // Re-pull and update the KDS listing
                            // ignore: invalid_use_of_internal_member
                            ref.invalidate(kitchenQueueNotifierProvider);
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
}
