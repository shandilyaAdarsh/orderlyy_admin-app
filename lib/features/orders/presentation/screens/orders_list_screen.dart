// ── Orders List Screen ───────────────────────────────────────────────────────
// Demonstrates offline-first architecture with:
// - Serializable state management
// - Optimistic updates
// - State persistence
// - Error handling

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_status.dart';
import '../../application/providers/orders_providers.dart';
import '../../application/state/orders_state.dart';
import '../../../../shared/models/failures.dart';

class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key});

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  OrderStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersStateProvider);
    final notifier = ref.read(ordersStateProvider.notifier);

    // Filter orders based on selected status
    final filteredOrders = _selectedStatus == null
        ? state.orders
        : state.orders.where((o) => o.status == _selectedStatus).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              pinned: true,
              backgroundColor: AppTheme.surfaceContainerLowest,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight: 64.h,
              title: Row(
                children: [
                  Text(
                    'Orders',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                  const Spacer(),
                  // Sync indicator
                  if (state.status == LoadingStatus.loading)
                    SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                  SizedBox(width: 8.w),
                  // Refresh button
                  IconButton(
                    icon: Icon(Icons.refresh, size: 20.r),
                    onPressed: () => notifier.refresh(),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(52.h),
                child: _StatusFilterBar(
                  selectedStatus: _selectedStatus,
                  onStatusSelected: (status) {
                    setState(() => _selectedStatus = status);
                  },
                ),
              ),
            ),

            // Error Banner
            if (state.error != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.all(16.r),
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.error,
                        size: 20.r,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          state.error!.when(
                            server: (msg, _) => 'Server error: $msg',
                            network: (msg) => 'Network error: $msg',
                            cache: (msg) => 'Cache error: $msg',
                            notFound: (msg) => 'Not found: $msg',
                            validation: (msg, _) => 'Validation error: $msg',
                            unauthorized: (msg) => 'Unauthorized: $msg',
                            unknown: (msg) => 'Error: $msg',
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Orders List
            if (state.status == LoadingStatus.loading && state.orders.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else if (filteredOrders.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    _selectedStatus == null
                        ? 'No orders yet'
                        : 'No ${_selectedStatus!.name} orders',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final order = filteredOrders[index];
                    return _OrderCard(order: order)
                        .animate(delay: Duration(milliseconds: 50 * index))
                        .fadeIn(duration: 400.ms);
                  }, childCount: filteredOrders.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Status Filter Bar ────────────────────────────────────────────────────────

class _StatusFilterBar extends StatelessWidget {
  final OrderStatus? selectedStatus;
  final ValueChanged<OrderStatus?> onStatusSelected;

  const _StatusFilterBar({
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [null, ...OrderStatus.values];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statuses.map((status) {
            final isSelected = selectedStatus == status;
            final label = status == null ? 'ALL' : status.name.toUpperCase();

            return GestureDetector(
              onTap: () => onStatusSelected(status),
              child: AnimatedContainer(
                duration: 200.ms,
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryContainer
                      : AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppTheme.secondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends ConsumerWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ordersStateProvider);
    final isOptimistic = state.optimisticIds.contains(order.id);
    final isFailed = state.failedIds.contains(order.id);

    return Container(
      padding: EdgeInsets.all(20.r),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        border: Border(
          left: BorderSide(
            color: isFailed
                ? AppTheme.error
                : isOptimistic
                ? Colors.orange
                : const Color(0xFF94A3B8),
            width: 4.w,
          ),
        ),
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TABLE ${order.tableLabel} · #${order.id.substring(0, 8)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.sp,
                        color: AppTheme.secondary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          order.displayStatus,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.schedule_rounded,
                          size: 12.r,
                          color: AppTheme.secondary,
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            order.displayTime,
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isOptimistic
                      ? Colors.orange.withValues(alpha: 0.2)
                      : isFailed
                      ? AppTheme.error.withValues(alpha: 0.2)
                      : AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  isOptimistic
                      ? 'SYNCING'
                      : isFailed
                      ? 'FAILED'
                      : order.status.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: isOptimistic
                        ? Colors.orange
                        : isFailed
                        ? AppTheme.error
                        : AppTheme.secondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Items
          ...order.items.take(3).map((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  Icon(
                    Icons.radio_button_unchecked,
                    size: 12.r,
                    color: AppTheme.surfaceDim,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      '${item.menuItemName} × ${item.quantity}',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          if (order.items.length > 3)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                '+ ${order.items.length - 3} more items',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          SizedBox(height: 16.h),

          // Total
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: OutlinedButton(
              onPressed: () => _showOrderDetails(context, order),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.surfaceContainerHigh),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                '${order.totalAmount.format()} - VIEW DETAILS',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondary,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _OrderDetailsSheet(order: order),
    );
  }
}

// ── Order Details Sheet ──────────────────────────────────────────────────────

class _OrderDetailsSheet extends ConsumerWidget {
  final Order order;

  const _OrderDetailsSheet({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 40.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
          SizedBox(height: 24.h),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Details',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  order.status.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryContainer,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          Text(
            'Table ${order.tableLabel} · Order #${order.id.substring(0, 8).toUpperCase()}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12.sp,
              color: AppTheme.secondary,
            ),
          ),

          SizedBox(height: 24.h),

          // Items
          Text(
            'ITEMS',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: AppTheme.secondary,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 12.h),

          ...order.items.map((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                children: [
                  Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Center(
                      child: Text(
                        '${item.quantity}x',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      item.menuItemName,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    item.subtotal.format(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 14.sp,
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
            );
          }),

          Divider(height: 32.h, color: AppTheme.surfaceContainerHigh),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.inter(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                order.totalAmount.format(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryContainer,
                ),
              ),
            ],
          ),

          SizedBox(height: 32.h),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryContainer,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.radiusMd,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
