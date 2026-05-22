import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/data/dtos/order_dto.dart';
import '../../core/providers/orders_providers.dart';
import '../../core/theme/app_theme.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _periodIndex = 0;
  static const _periods = ['Today', 'Week', 'Month'];

  static List<OrderDto> _filterByPeriod(List<OrderDto> orders, int idx) {
    final now = DateTime.now();
    final cutoff = switch (idx) {
      1 => now.subtract(const Duration(days: 7)),
      2 => now.subtract(const Duration(days: 30)),
      _ => DateTime(now.year, now.month, now.day),
    };
    return orders.where((o) => o.createdAt.toLocal().isAfter(cutoff)).toList();
  }

  static String _fmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersStreamProvider);

    return ordersAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryContainer),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Text(
            'Sync Error: $err',
            style: GoogleFonts.inter(color: AppTheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (allOrders) {
        final orders = _filterByPeriod(allOrders, _periodIndex);

        final totalRevenue = orders
            .where((o) => o.status == OrderStatus.served)
            .fold<double>(0, (s, o) => s + o.totalAmount);
        final orderCount = orders.length;
        final avgOrder = orderCount > 0 ? totalRevenue / orderCount : 0.0;
        final pendingRevenue = orders
            .where(
              (o) =>
                  o.status != OrderStatus.served &&
                  o.status != OrderStatus.cancelled,
            )
            .fold<double>(0, (s, o) => s + o.totalAmount);

        // Status breakdown
        final statusCounts = <OrderStatus, int>{};
        for (final o in orders) {
          statusCounts[o.status] = (statusCounts[o.status] ?? 0) + 1;
        }

        // Best sellers
        final itemCounts = <String, int>{};
        for (final o in orders) {
          for (final item in o.items) {
            itemCounts[item.menuItemName] =
                (itemCounts[item.menuItemName] ?? 0) + item.quantity;
          }
        }
        final topItems =
            (itemCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .take(5)
                .toList();
        final maxCount = topItems.isNotEmpty ? topItems.first.value : 1;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── App Bar ──────────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppTheme.surfaceContainerLowest,
                  elevation: 0,
                  toolbarHeight: 64.h,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(
                      height: 1,
                      color: AppTheme.surfaceContainerHigh,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        'Orderlli',
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryContainer,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Container(
                        width: 1.w,
                        height: 18.h,
                        color: AppTheme.surfaceContainerHigh,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Analytics',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 100.h),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Period Selector ──────────────────────────────────────
                      Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Row(
                          children: List.generate(_periods.length, (i) {
                            final active = _periodIndex == i;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _periodIndex = i),
                                child: AnimatedContainer(
                                  duration: 200.ms,
                                  padding: EdgeInsets.symmetric(vertical: 10.h),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppTheme.primaryContainer
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10.r),
                                    boxShadow: active
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primaryContainer
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _periods[i],
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                      color: active
                                          ? Colors.white
                                          : AppTheme.secondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // ── Revenue Hero ─────────────────────────────────────────
                      _AnalyticsHeroCard(
                        revenue: totalRevenue,
                        pending: pendingRevenue,
                        fmt: _fmt,
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06),
                      SizedBox(height: 14.h),

                      // ── KPI Row ──────────────────────────────────────────────
                      Row(
                        children: [
                          _AnalyticsKpiCard(
                            label: 'ORDERS',
                            value: '$orderCount',
                            icon: Icons.receipt_long_outlined,
                            color: const Color(0xFF3B82F6),
                          ),
                          SizedBox(width: 10.w),
                          _AnalyticsKpiCard(
                            label: 'AVG ORDER',
                            value: _fmt(avgOrder),
                            icon: Icons.shopping_bag_outlined,
                            color: const Color(0xFF8B5CF6),
                          ),
                          SizedBox(width: 10.w),
                          _AnalyticsKpiCard(
                            label: 'CUSTOMERS',
                            value: '${(orderCount * 1.2).toInt()}',
                            icon: Icons.people_outline,
                            color: const Color(0xFF10B981),
                          ),
                        ],
                      ).animate(delay: 100.ms).fadeIn(duration: 350.ms),
                      SizedBox(height: 20.h),

                      // ── Sales Trend ──────────────────────────────────────────
                      _SalesTrendCard(
                        orders: orders,
                        periodIdx: _periodIndex,
                      ).animate(delay: 150.ms).fadeIn(duration: 350.ms),
                      SizedBox(height: 16.h),

                      // ── Order Status Breakdown ───────────────────────────────
                      _StatusBreakdownCard(
                        statusCounts: statusCounts,
                        total: orderCount,
                      ).animate(delay: 200.ms).fadeIn(duration: 350.ms),
                      SizedBox(height: 16.h),

                      // ── Best Sellers ─────────────────────────────────────────
                      _BestSellersCard(
                        topItems: topItems,
                        maxCount: maxCount,
                      ).animate(delay: 250.ms).fadeIn(duration: 350.ms),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Analytics Hero Card ───────────────────────────────────────────────────────
class _AnalyticsHeroCard extends StatelessWidget {
  final double revenue;
  final double pending;
  final String Function(double) fmt;
  const _AnalyticsHeroCard({
    required this.revenue,
    required this.pending,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC0272D), Color(0xFF7F1D1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC0272D).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL COLLECTED',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.65),
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 6.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    fmt(revenue),
                    style: GoogleFonts.inter(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60.h,
            color: Colors.white.withValues(alpha: 0.2),
            margin: EdgeInsets.symmetric(horizontal: 16.w),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PENDING',
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                fmt(pending),
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'in progress',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Analytics KPI Card ────────────────────────────────────────────────────────
class _AnalyticsKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _AnalyticsKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28.r,
              height: 28.r,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: color, size: 14.r),
            ),
            SizedBox(height: 8.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                  height: 1.0,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sales Trend Card ──────────────────────────────────────────────────────────
class _SalesTrendCard extends StatelessWidget {
  final List<OrderDto> orders;
  final int periodIdx;
  const _SalesTrendCard({required this.orders, required this.periodIdx});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final buckets = periodIdx == 0
        ? 12
        : periodIdx == 1
        ? 7
        : 30;
    final totals = List.filled(buckets, 0.0);
    final labels = List.filled(buckets, '');

    for (int i = 0; i < buckets; i++) {
      if (periodIdx == 0) {
        final dt = now.subtract(Duration(hours: (buckets - 1 - i) * 2));
        labels[i] = '${dt.hour}h';
      } else if (periodIdx == 1) {
        final dt = now.subtract(Duration(days: buckets - 1 - i));
        labels[i] = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'][dt.weekday % 7];
      } else {
        final dt = now.subtract(Duration(days: buckets - 1 - i));
        labels[i] = '${dt.day}';
      }
    }

    for (final o in orders) {
      if (o.status != OrderStatus.served) continue;
      final dt = o.createdAt.toLocal();
      for (int i = 0; i < buckets; i++) {
        DateTime start, end;
        if (periodIdx == 0) {
          end = now.subtract(Duration(hours: (buckets - 1 - i) * 2));
          start = end.subtract(const Duration(hours: 2));
        } else {
          end = now.subtract(Duration(days: buckets - 1 - i));
          start = end.subtract(const Duration(days: 1));
        }
        if (dt.isAfter(start) &&
            dt.isBefore(end.add(const Duration(milliseconds: 1)))) {
          totals[i] += o.totalAmount;
          break;
        }
      }
    }

    final maxTotal = totals.isNotEmpty
        ? totals.reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                color: AppTheme.primaryContainer,
                size: 18.r,
              ),
              SizedBox(width: 8.w),
              Text(
                'SALES TREND',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 120.h,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(totals.length, (i) {
                  final frac = maxTotal <= 0 ? 0.0 : (totals[i] / maxTotal);
                  final barH = (8.h + (frac * 90.h)).clamp(6.h, 100.h);
                  final isLast = i == totals.length - 1;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 16.w,
                          height: barH,
                          decoration: BoxDecoration(
                            color: isLast
                                ? AppTheme.primaryContainer
                                : AppTheme.primaryContainer.withValues(
                                    alpha: 0.35,
                                  ),
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        SizedBox(
                          width: 26.w,
                          child: Text(
                            labels[i],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              color: AppTheme.secondary,
                              fontWeight: isLast
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Breakdown Card ─────────────────────────────────────────────────────
class _StatusBreakdownCard extends StatelessWidget {
  final Map<OrderStatus, int> statusCounts;
  final int total;
  const _StatusBreakdownCard({required this.statusCounts, required this.total});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        status: OrderStatus.served,
        label: 'Served',
        color: const Color(0xFF10B981),
      ),
      (
        status: OrderStatus.preparing,
        label: 'Preparing',
        color: const Color(0xFF3B82F6),
      ),
      (
        status: OrderStatus.pending,
        label: 'Pending',
        color: const Color(0xFFF59E0B),
      ),
      (
        status: OrderStatus.cancelled,
        label: 'Cancelled',
        color: AppTheme.error,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.donut_small_rounded,
                color: AppTheme.primaryContainer,
                size: 18.r,
              ),
              SizedBox(width: 8.w),
              Text(
                'ORDER STATUS',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...items.map((item) {
            final count = statusCounts[item.status] ?? 0;
            final pct = total > 0 ? count / total : 0.0;
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8.r,
                            height: 8.r,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            item.label,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: AppTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '$count',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 5.h,
                      backgroundColor: AppTheme.surfaceContainerLow,
                      color: item.color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Best Sellers Card ─────────────────────────────────────────────────────────
class _BestSellersCard extends StatelessWidget {
  final List<MapEntry<String, int>> topItems;
  final int maxCount;
  const _BestSellersCard({required this.topItems, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFC0272D),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
    ];

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.amber, size: 18.r),
              SizedBox(width: 8.w),
              Text(
                'TOP SELLERS',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (topItems.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text(
                  'No sales data yet',
                  style: GoogleFonts.inter(color: AppTheme.secondary),
                ),
              ),
            )
          else
            ...topItems.asMap().entries.map((e) {
              final item = e.value;
              final pct = item.value / maxCount;
              final color = colors[e.key % colors.length];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  children: [
                    Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.key,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${item.value} sold',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 5.h,
                              backgroundColor: AppTheme.surfaceContainerLow,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
