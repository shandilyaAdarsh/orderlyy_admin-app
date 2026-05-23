import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/data/dtos/order_dto.dart';
import '../../core/providers/orders_providers.dart';
import '../../core/theme/app_theme.dart';

// ── Screen ────────────────────────────────────────────────────────────────────
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  int _filterIndex = 0;
  static const _filters = ['ALL', 'PENDING', 'COOKING', 'READY', 'SERVED'];

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ordersAsync.when(
          error: (err, _) => Center(
            child: Text(
              'Order Sync Error: $err',
              style: GoogleFonts.inter(color: AppTheme.error),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          data: (allOrders) {
            // Filter orders based on _filterIndex
            final orders = allOrders.where((o) {
              if (_filterIndex == 0) return true; // ALL
              final status = o.displayStatus;
              return status == _filters[_filterIndex];
            }).toList();

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppTheme.surfaceContainerLowest,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 64.h,
                  title: Text(
                    'Orderlli',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(52.h),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_filters.length, (i) {
                            final active = _filterIndex == i;
                            return GestureDetector(
                              onTap: () => setState(() => _filterIndex = i),
                              child: AnimatedContainer(
                                duration: 200.ms,
                                margin: EdgeInsets.only(right: 8.w),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppTheme.primaryContainer
                                      : AppTheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  _filters[i],
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? Colors.white
                                        : AppTheme.secondary,
                                    letterSpacing: 0.8,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final orderIndex = index;
                      if (orders.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.r),
                            child: Text(
                              "No live orders found.",
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: AppTheme.secondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }
                      if (orderIndex < orders.length) {
                        return _DynamicOrderCard(order: orders[orderIndex])
                            .animate(
                              delay: Duration(milliseconds: 50 * orderIndex),
                            )
                            .fadeIn(duration: 400.ms);
                      }
                      return null;
                    }, childCount: orders.isEmpty ? 1 : orders.length),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Dynamic Order Card ─────────────────────────────────────────────────────────
class _DynamicOrderCard extends StatelessWidget {
  final OrderDto order;
  const _DynamicOrderCard({required this.order});

  void _showOrderDetails(BuildContext context, OrderDto order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _OrderDetailsSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tableId = order.tableLabel;
    final orderId = order.id.length >= 8 ? order.id.substring(0, 8) : order.id;
    final status = order.displayStatus;
    final amount = order.totalAmount.toStringAsFixed(2);
    final timeLabel = order.displayTime;
    final itemsList = order.items;

    return Container(
      padding: EdgeInsets.all(20.r),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        border: Border(
          left: BorderSide(color: const Color(0xFF94A3B8), width: 4.w),
        ),
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TABLE $tableId · #$orderId',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.sp,
                        color: AppTheme.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          status,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (timeLabel.isNotEmpty) ...[
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.schedule_rounded,
                            size: 12.r,
                            color: AppTheme.secondary,
                          ),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: Text(
                              timeLabel,
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: AppTheme.secondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.secondary,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (itemsList.isEmpty)
            Text(
              'No items details found',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppTheme.secondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ...itemsList.take(3).map((item) {
            final itemName = item.menuItemName;
            final qty = item.quantity;
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
                      '$itemName × $qty',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: AppTheme.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (itemsList.length > 3)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                '+ ${itemsList.length - 3} more items',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          SizedBox(height: 16.h),
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
                '₹$amount - VIEW DETAILS',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondary,
                  letterSpacing: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Order Details Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _OrderDetailsSheet extends StatelessWidget {
  final OrderDto order;
  const _OrderDetailsSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final items = order.items;
    final tableId = order.tableLabel;
    final amount = order.totalAmount.toStringAsFixed(0);
    final status = order.displayStatus;
    final timeLabel = order.displayTime;

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
                  status,
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
          Row(
            children: [
              Text(
                'Table $tableId · Order #${(() {
                  return (order.id.length >= 8 ? order.id.substring(0, 8) : order.id).toUpperCase();
                })()}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12.sp,
                  color: AppTheme.secondary,
                ),
              ),
              if (timeLabel.isNotEmpty) ...[
                SizedBox(width: 8.w),
                Icon(
                  Icons.schedule_rounded,
                  size: 12.r,
                  color: AppTheme.secondary,
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    timeLabel,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppTheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 24.h),
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
          ...items.map((i) {
            final name = i.menuItemName;
            final qty = i.quantity;
            final price = i.unitPrice > 0 ? i.lineTotal.toStringAsFixed(0) : '';
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
                        '${qty}x',
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
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (price.isNotEmpty)
                    Text(
                      '₹$price',
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
                '₹$amount',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryContainer,
                ),
              ),
            ],
          ),
          SizedBox(height: 32.h),
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
