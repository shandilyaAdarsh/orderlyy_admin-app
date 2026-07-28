import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_status.dart';
import '../../providers/live_active_orders_provider.dart';


class ActiveOrdersFeedScreen extends ConsumerStatefulWidget {
  const ActiveOrdersFeedScreen({super.key});

  @override
  ConsumerState<ActiveOrdersFeedScreen> createState() =>
      _ActiveOrdersFeedScreenState();
}

class _ActiveOrdersFeedScreenState extends ConsumerState<ActiveOrdersFeedScreen> {
  OrderStatus? _statusFilter;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Orders Feed'),
        actions: [

          const SizedBox(width: 8),
        ],
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final ordersAsync = ref.watch(liveActiveOrdersProvider);
          return ordersAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (rawOrders) {
              var orders = rawOrders
                  .where((o) =>
                      o.status != OrderStatus.served &&
                      o.status != OrderStatus.cancelled)
                  .toList();

              if (_statusFilter != null) {
                orders = orders.where((o) => o.status == _statusFilter).toList();
              }

              orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterChips(theme, isDark),
                  Expanded(
                    child: orders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_turned_in_rounded,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text('No active orders found.'),
                              ],
                            ),
                          )
                        : CustomScrollView(
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.all(16),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) =>
                                        _buildOrderCard(orders[index], theme, isDark),
                                    childCount: orders.length,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            selected: _statusFilter == null,
            label: const Text('All Active'),
            onSelected: (selected) {
              setState(() {
                _statusFilter = null;
              });
            },
          ),
          const SizedBox(width: 8),
          ...<OrderStatus>[
            OrderStatus.pending,
            OrderStatus.confirmed,
            OrderStatus.preparing,
            OrderStatus.ready,
          ].map((OrderStatus status) {
            final label =
                status.name[0].toUpperCase() + status.name.substring(1);
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                selected: _statusFilter == status,
                label: Text(label),
                onSelected: (selected) {
                  setState(() {
                    _statusFilter = selected ? status : null;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, ThemeData theme, bool isDark) {
    final hasPaymentIntent = order.customerPaymentIntent != null;
    final paymentLabel = order.customerPaymentIntent == 'upi' ? 'UPI PENDING' : 'CASH REQ';

    Widget card = Card(
      color: hasPaymentIntent 
          ? (isDark ? Colors.orange.withValues(alpha: 0.2) : Colors.orange.shade50)
          : (isDark ? AppColors.darkSurface : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasPaymentIntent 
              ? Colors.orange 
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: hasPaymentIntent ? 2.0 : 1.0,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push('/orders/${order.id}/details');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Table ${order.tableId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Row(
                    children: [
                      if (hasPaymentIntent) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            paymentLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.status.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),

                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        Text(
                          '${item.quantity}x ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.menuItemName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    return card;
  }
}
