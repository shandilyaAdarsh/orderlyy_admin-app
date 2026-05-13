import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _periodIndex = 0;
  static const _periods = ['TODAY', 'WEEK', 'MONTH'];
  String? _currentTenantId;

  @override
  void initState() {
    super.initState();
    _loadTenantId();
  }

  Future<void> _loadTenantId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final metaTenant =
          user.userMetadata?['tenant_id']?.toString() ??
          user.userMetadata?['business_id']?.toString();
      if (metaTenant != null) {
        setState(() => _currentTenantId = metaTenant);
        return;
      }
      // Try profile, but catch recursion
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('tenant_id')
            .eq('id', user.id)
            .maybeSingle();
        if (profile != null) {
          setState(() => _currentTenantId = profile['tenant_id']?.toString());
          return;
        }
      } catch (e) {
        debugPrint('Analytics: Profile fetch failed: $e');
      }

      // Fallback: Check orders for a tenant_id
      try {
        final orderCheck = await Supabase.instance.client
            .from('orders')
            .select('tenant_id')
            .limit(1)
            .maybeSingle();
        if (orderCheck != null) {
          setState(
            () => _currentTenantId = orderCheck['tenant_id']?.toString(),
          );
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('Analytics: Error loading tenant: $e');
    }
  }

  static List<Map<String, dynamic>> _filterByPeriod(
    List<Map<String, dynamic>> orders,
    int periodIdx,
  ) {
    final now = DateTime.now();
    late DateTime cutoff;
    switch (periodIdx) {
      case 1:
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case 2:
        cutoff = now.subtract(const Duration(days: 30));
        break;
      default:
        cutoff = DateTime(now.year, now.month, now.day);
    }
    return orders.where((o) {
      final raw = o['created_at'];
      if (raw == null) return false;
      try {
        return DateTime.parse(raw.toString()).toLocal().isAfter(cutoff);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTenantId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Create a safe stream for orders: realtime if available, otherwise fall back
    Stream<List<Map<String, dynamic>>> ordersStream;
    try {
      ordersStream = Supabase.instance.client
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('tenant_id', _currentTenantId!)
          .order('created_at', ascending: false);
    } catch (e) {
      debugPrint('Orders realtime stream unavailable: $e');
      ordersStream = Stream.fromFuture(
        Future(() async {
          try {
            final data = await Supabase.instance.client
                .from('orders')
                .select()
                .eq('tenant_id', _currentTenantId!);
            return List<Map<String, dynamic>>.from(data.cast<Map>());
          } catch (e) {
            debugPrint('Orders one-shot fetch failed: $e');
          }
          return <Map<String, dynamic>>[];
        }),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Orders Sync Error: ${snapshot.error}');
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Text(
                'Orders Sync Error: ${snapshot.error}',
                style: TextStyle(color: AppTheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final allOrders = snapshot.data ?? [];
        final orders = _filterByPeriod(allOrders, _periodIndex);

        double extractCollected(Map<String, dynamic> o) {
          final paidNum =
              (o['paid_amount'] ?? o['amount_paid'] ?? o['collected_amount'])
                  as num?;
          if (paidNum != null) return paidNum.toDouble();
          final status = (o['status'] ?? '').toString().toLowerCase();
          if (['closed', 'paid', 'settled', 'completed'].contains(status)) {
            return ((o['total_amount'] as num?)?.toDouble() ?? 0);
          }
          return 0.0;
        }

        final totalCollection = orders.fold<double>(
          0,
          (s, o) => s + extractCollected(o),
        );
        final orderCount = orders.length;
        final avgOrder = orderCount > 0 ? totalCollection / orderCount : 0.0;

        String fmt(double v) {
          if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
          if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
          return '₹${v.toStringAsFixed(0)}';
        }

        final Map<String, int> itemCounts = {};
        for (final o in orders) {
          final items = o['items'];
          if (items is List) {
            for (final item in items) {
              if (item is Map) {
                final name = (item['name'] ?? 'Unknown').toString();
                final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                itemCounts[name] = (itemCounts[name] ?? 0) + qty;
              }
            }
          }
        }
        final sortedItems = itemCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top4 = sortedItems.take(4).toList();
        final maxCount = top4.isNotEmpty ? top4.first.value : 1;
        // Payment breakdown
        double collected = 0;
        double pending = 0;
        final Map<String, double> byMethod = {};
        for (final o in orders) {
          final col = extractCollected(o);
          collected += col;
          final total = ((o['total_amount'] as num?)?.toDouble() ?? 0);
          if (col < total) pending += (total - col);
          final method = (o['payment_method'] ?? 'UNKNOWN')
              .toString()
              .toUpperCase();
          byMethod[method] = (byMethod[method] ?? 0) + col;
        }
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.surfaceContainerLowest,
            elevation: 0,
            title: Text(
              'Restaurant Analytics',
              style: AppTheme.titleLg.copyWith(color: AppTheme.primary),
            ),
            actions: [
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.all(20.r),
            children: [
              // Period Selector
              Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12.r),
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
                                ? AppTheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _periods[i],
                            style: AppTheme.labelSm.copyWith(
                              color: active ? Colors.white : AppTheme.secondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(height: 24.h),

              // Summary Cards
              _MetricRow(
                metrics: [
                  _MetricData(
                    label: 'TOTAL COLLECTION',
                    value: fmt(totalCollection),
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF10B981),
                  ),
                  _MetricData(
                    label: 'ORDERS',
                    value: '$orderCount',
                    icon: Icons.receipt_long_outlined,
                    color: Colors.blue,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _MetricRow(
                metrics: [
                  _MetricData(
                    label: 'AVG ORDER',
                    value: fmt(avgOrder),
                    icon: Icons.analytics_outlined,
                    color: Colors.orange,
                  ),
                  _MetricData(
                    label: 'CUSTOMERS',
                    value: '${(orderCount * 1.2).toInt()}',
                    icon: Icons.people_outline,
                    color: Colors.purple,
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Best Sellers
              _LiveBestSellersCard(
                top4: top4,
                maxCount: maxCount,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
              SizedBox(height: 20.h),

              // Sales Chart
              _SalesTrendCard(
                orders: orders,
                periodIdx: _periodIndex,
              ).animate(delay: 200.ms).fadeIn(),
              SizedBox(height: 16.h),

              // Collection Breakdown
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppTheme.surfaceContainer),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('COLLECTION BREAKDOWN', style: AppTheme.titleSm),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Collected', style: AppTheme.labelMd),
                        Text(
                          fmt(collected),
                          style: AppTheme.monoLg.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pending', style: AppTheme.labelMd),
                        Text(
                          fmt(pending),
                          style: AppTheme.monoLg.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    if (byMethod.isNotEmpty)
                      ...byMethod.entries.map(
                        (e) => Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key, style: AppTheme.labelSm),
                              Text(fmt(e.value), style: AppTheme.monoMd),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _MetricRow extends StatelessWidget {
  final List<_MetricData> metrics;
  const _MetricRow({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: metrics
          .map(
            (m) => Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: m == metrics.first ? 6.w : 0,
                  left: m == metrics.last ? 6.w : 0,
                ),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppTheme.surfaceContainer),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(m.icon, color: m.color, size: 20.r),
                        Text(
                          m.label,
                          style: AppTheme.labelSm.copyWith(fontSize: 9.sp),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      m.value,
                      style: AppTheme.monoLg.copyWith(
                        fontSize: 20.sp,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LiveBestSellersCard extends StatelessWidget {
  final List<MapEntry<String, int>> top4;
  final int maxCount;
  const _LiveBestSellersCard({required this.top4, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppTheme.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.amber, size: 20.r),
              SizedBox(width: 8.w),
              Text('TOP SELLERS', style: AppTheme.titleSm),
            ],
          ),
          SizedBox(height: 20.h),
          if (top4.isEmpty)
            Center(child: Text('No sales data yet', style: AppTheme.bodySm))
          else
            ...top4.map((item) {
              final percent = item.value / maxCount;
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.key,
                          style: AppTheme.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text('${item.value} sold', style: AppTheme.labelMd),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 6.h,
                        backgroundColor: AppTheme.surfaceContainer,
                        color: AppTheme.primary,
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

class _SalesTrendCard extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final int periodIdx;
  const _SalesTrendCard({required this.orders, required this.periodIdx});

  @override
  Widget build(BuildContext context) {
    // Aggregate orders into buckets depending on periodIdx
    final now = DateTime.now();
    final int buckets = periodIdx == 0
        ? 24
        : periodIdx == 1
        ? 7
        : 30;
    final List<double> totals = List.filled(buckets, 0.0);
    final List<String> labels = List.filled(buckets, '');

    for (int i = 0; i < buckets; i++) {
      if (periodIdx == 0) {
        // last 24 hours, label as hour
        final dt = now.subtract(Duration(hours: buckets - 1 - i));
        labels[i] = '${dt.hour}h';
      } else if (periodIdx == 1) {
        final dt = now.subtract(Duration(days: buckets - 1 - i));
        labels[i] = [
          'Sun',
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
        ][dt.weekday % 7];
      } else {
        final dt = now.subtract(Duration(days: buckets - 1 - i));
        labels[i] = '${dt.day}';
      }
    }

    double extractCollected(Map<String, dynamic> o) {
      final paidNum =
          (o['paid_amount'] ?? o['amount_paid'] ?? o['collected_amount'])
              as num?;
      if (paidNum != null) return paidNum.toDouble();
      final status = (o['status'] ?? '').toString().toLowerCase();
      if (['closed', 'paid', 'settled', 'completed'].contains(status)) {
        return ((o['total_amount'] as num?)?.toDouble() ?? 0);
      }
      return 0.0;
    }

    for (final o in orders) {
      final raw = o['created_at'];
      if (raw == null) continue;
      DateTime dt;
      try {
        dt = DateTime.parse(raw.toString()).toLocal();
      } catch (_) {
        continue;
      }
      for (int i = 0; i < buckets; i++) {
        DateTime start, end;
        if (periodIdx == 0) {
          end = now.subtract(Duration(hours: buckets - 1 - i - 0));
          start = end.subtract(const Duration(hours: 1));
        } else {
          end = now.subtract(Duration(days: buckets - 1 - i));
          start = end.subtract(const Duration(days: 1));
        }
        if (dt.isAfter(start) &&
            dt.isBefore(end.add(const Duration(milliseconds: 1)))) {
          totals[i] += extractCollected(o);
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
        border: Border.all(color: AppTheme.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SALES TREND', style: AppTheme.titleSm),
          SizedBox(height: 16.h),
          SizedBox(
            height: 140.h,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(totals.length, (i) {
                  final frac = maxTotal <= 0 ? 0.0 : (totals[i] / maxTotal);
                  final barH = (20.h + (frac * 100.h)).clamp(6.h, 120.h);
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 14.w,
                          height: barH,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(
                              alpha: i == totals.length - 1 ? 1.0 : 0.6,
                            ),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        SizedBox(
                          width: 28.w,
                          child: Text(
                            labels[i],
                            textAlign: TextAlign.center,
                            style: AppTheme.labelSm.copyWith(fontSize: 9.sp),
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
