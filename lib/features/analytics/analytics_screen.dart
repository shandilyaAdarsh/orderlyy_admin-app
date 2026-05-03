import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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



  static List<Map<String, dynamic>> _filterByPeriod(
      List<Map<String, dynamic>> orders, int periodIdx) {
    final now = DateTime.now();
    late DateTime cutoff;
    switch (periodIdx) {
      case 1:
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case 2:
        cutoff = DateTime(now.year, now.month, 1);
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
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('orders').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        final allOrders = snapshot.data ?? [];
        final orders = _filterByPeriod(allOrders, _periodIndex);

        // ── Aggregate KPIs ────────────────────────────────────────────────
        final revenue = orders.fold<double>(
            0, (s, o) => s + ((o['total_amount'] as num?)?.toDouble() ?? 0));
        final orderCount = orders.length;
        final avgOrder = orderCount > 0 ? revenue / orderCount : 0.0;

        // ── Best sellers ──────────────────────────────────────────────────
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

        final isLoading =
            snapshot.connectionState == ConnectionState.waiting && allOrders.isEmpty;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.surfaceContainerLowest,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            toolbarHeight: 64.h,
            title: Text('Orderlli',
                style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary)),
            actions: [
              if (isLoading)
                Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: SizedBox(
                      width: 18.r,
                      height: 18.r,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primaryContainer)),
                ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 100.h),
            children: [
              // ── Title + period pills ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('Analytics',
                        style: GoogleFonts.inter(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                            letterSpacing: -0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(width: 8.w),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: List.generate(_periods.length, (i) {
                        final active = _periodIndex == i;
                        return GestureDetector(
                          onTap: () => setState(() => _periodIndex = i),
                          child: AnimatedContainer(
                            duration: 200.ms,
                            margin: EdgeInsets.only(left: 6.w),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 7.h),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppTheme.primaryContainer
                                  : AppTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(_periods[i],
                                style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? Colors.white
                                        : AppTheme.secondary,
                                    letterSpacing: 0.8)),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // ── Revenue Hero Card ─────────────────────────────────────────
              _RevenueHeroCard(revenue: revenue, orderCount: orderCount)
                  .animate()
                  .fadeIn(duration: 400.ms),
              SizedBox(height: 16.h),

              // ── KPI Strip ────────────────────────────────────────────────
              _LiveKpiStrip(
                      revenue: revenue,
                      orderCount: orderCount,
                      avgOrder: avgOrder)
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 400.ms),
              SizedBox(height: 24.h),

              // ── Best Sellers ──────────────────────────────────────────────
              _LiveBestSellersCard(top4: top4, maxCount: maxCount)
                  .animate(delay: 150.ms)
                  .fadeIn(duration: 400.ms),
              SizedBox(height: 16.h),

              // ── Station Distribution (visual placeholder) ─────────────────
              const _StationDonutCard()
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms),
              SizedBox(height: 16.h),

              // ── Peak Hours (visual placeholder) ──────────────────────────
              const _PeakHoursCard()
                  .animate(delay: 250.ms)
                  .fadeIn(duration: 400.ms),
            ],
          ),
        );
      },
    );
  }
}

// ── Revenue Hero Card (live) ──────────────────────────────────────────────────
class _RevenueHeroCard extends StatelessWidget {
  final double revenue;
  final int orderCount;
  const _RevenueHeroCard({required this.revenue, required this.orderCount});

  String _fmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
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
                    Text('Revenue',
                        style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 4.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(_fmt(revenue),
                          style: GoogleFonts.inter(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.onSurface)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        color: AppTheme.primaryContainer, size: 14.r),
                    SizedBox(width: 4.w),
                    Text('$orderCount orders',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryContainer)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 140.h,
            child: CustomPaint(
                painter: _RevenuePainter(), size: Size.infinite),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final h in ['8AM', '10AM', '12PM', '2PM', '4PM', '6PM', '8PM'])
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(h,
                        style: GoogleFonts.inter(
                            fontSize: 9.sp, color: AppTheme.secondary)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenuePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const pts = [0.3, 0.5, 0.8, 0.95, 0.85, 1.0, 0.7];
    final w = size.width;
    final h = size.height;
    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < pts.length; i++) {
      final x = w * i / (pts.length - 1);
      final y = h * (1 - pts[i] * 0.85);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath..lineTo(w, h)..close();
    canvas.drawPath(
        fillPath,
        Paint()
          ..shader = const LinearGradient(
                  colors: [Color(0x22C0272D), Color(0x00C0272D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)
              .createShader(Rect.fromLTWH(0, 0, w, h)));
    canvas.drawPath(
        path,
        Paint()
          ..color = AppTheme.primaryContainer
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    final dotPaint = Paint()
      ..color = AppTheme.primaryContainer
      ..style = PaintingStyle.fill;
    final dotBorder = Paint()
      ..color = AppTheme.surface
      ..style = PaintingStyle.fill;
    for (var i = 0; i < pts.length; i++) {
      final x = w * i / (pts.length - 1);
      final y = h * (1 - pts[i] * 0.85);
      canvas.drawCircle(Offset(x, y), 5.r, dotBorder);
      canvas.drawCircle(Offset(x, y), 3.5.r, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Live KPI Strip ────────────────────────────────────────────────────────────
class _LiveKpiStrip extends StatelessWidget {
  final double revenue;
  final int orderCount;
  final double avgOrder;
  const _LiveKpiStrip(
      {required this.revenue,
      required this.orderCount,
      required this.avgOrder});

  String _fmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final kpis = [
      ('Revenue', _fmt(revenue), ''),
      ('Orders', '$orderCount', ''),
      ('Avg Order', _fmt(avgOrder), ''),
    ];
    return SizedBox(
      height: 105.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kpis.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.w),
        itemBuilder: (context, i) {
          final (label, value, _) = kpis[i];
          return Container(
            width: 130.w,
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: AppTheme.radiusMd,
              border: Border(
                  bottom: BorderSide(
                      color: AppTheme.surfaceContainerHigh, width: 2.h)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Live Best Sellers ─────────────────────────────────────────────────────────
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
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Best Sellers',
              style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface)),
          SizedBox(height: 16.h),
          if (top4.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text('No order data yet',
                    style: GoogleFonts.inter(
                        fontSize: 13.sp, color: AppTheme.secondary)),
              ),
            )
          else
            ...top4.map((entry) {
              final ratio = maxCount > 0 ? entry.value / maxCount : 0.0;
              return Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(entry.key,
                              style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        SizedBox(width: 12.w),
                        Text('${entry.value} orders',
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 11.sp, color: AppTheme.secondary)),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9999.r),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: AppTheme.surfaceContainer,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryContainer
                                .withValues(alpha: 0.5 + 0.5 * ratio)),
                        minHeight: 8.h,
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

// ── Station Donut (visual) ────────────────────────────────────────────────────
class _StationDonutCard extends StatelessWidget {
  const _StationDonutCard();

  @override
  Widget build(BuildContext context) {
    const stations = [
      ('Tandoor', 0.38, Color(0xFFC0272D)),
      ('Grill', 0.26, Color(0xFFEF4444)),
      ('Bar', 0.21, Color(0xFFFCA5A5)),
      ('Cold Station', 0.15, Color(0xFFE2E8F0)),
    ];
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Station Distribution',
              style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface)),
          SizedBox(height: 20.h),
          Row(
            children: [
              Flexible(
                flex: 2,
                child: SizedBox(
                  width: 130.r,
                  height: 130.r,
                  child: CustomPaint(
                    painter: _DonutPainter(
                        stations.map((s) => (s.$2, s.$3)).toList()),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('—',
                              style: GoogleFonts.inter(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.onSurface)),
                          Text('STATIONS',
                              style: GoogleFonts.inter(
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.secondary,
                                  letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                flex: 3,
                child: Column(
                  children: stations
                      .map((s) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(children: [
                                    Container(
                                        width: 10.r,
                                        height: 10.r,
                                        decoration: BoxDecoration(
                                            color: s.$3,
                                            shape: BoxShape.circle)),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                        child: Text(s.$1,
                                            style: GoogleFonts.inter(
                                                fontSize: 12.sp,
                                                color: AppTheme.secondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis)),
                                  ]),
                                ),
                                SizedBox(width: 8.w),
                                Text('${(s.$2 * 100).toInt()}%',
                                    style: GoogleFonts.jetBrainsMono(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.onSurface)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<(double, Color)> segments;
  _DonutPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4.r;
    final strokeWidth = 22.0.r;
    const gap = 0.04;
    var startAngle = -pi / 2;
    for (final (ratio, color) in segments) {
      final sweep = 2 * pi * ratio - gap;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle + gap / 2,
        sweep,
        false,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      startAngle += 2 * pi * ratio;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Peak Hours (visual) ───────────────────────────────────────────────────────
class _PeakHoursCard extends StatelessWidget {
  const _PeakHoursCard();

  static const _hours = ['8AM', '10AM', '12PM', '2PM', '4PM', '6PM', '8PM'];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  static const _heat = [
    [0.1, 0.2, 0.8, 0.9, 0.6, 1.0, 0.8],
    [0.2, 0.3, 0.5, 0.7, 0.4, 0.9, 0.7],
    [0.1, 0.2, 0.7, 0.8, 0.5, 0.95, 0.75],
    [0.3, 0.4, 0.6, 0.8, 0.6, 0.85, 0.7],
    [0.5, 0.6, 0.9, 1.0, 0.8, 1.0, 0.9],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Peak Hours',
              style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface)),
          SizedBox(height: 4.h),
          Text('Order density by hour and day',
              style:
                  GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.secondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.only(left: 36.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _hours
                  .map((h) => Text(h,
                      style: GoogleFonts.inter(
                          fontSize: 8.sp, color: AppTheme.secondary)))
                  .toList(),
            ),
          ),
          SizedBox(height: 8.h),
          ...List.generate(
            _days.length,
            (row) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(children: [
                SizedBox(
                    width: 30.w,
                    child: Text(_days[row],
                        style: GoogleFonts.inter(
                            fontSize: 10.sp, color: AppTheme.secondary))),
                ...List.generate(_hours.length, (col) {
                  final v = _heat[row][col];
                  return Expanded(
                    child: Container(
                      height: 22.h,
                      margin: EdgeInsets.symmetric(horizontal: 2.w),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer
                            .withValues(alpha: v * 0.85 + 0.05),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  );
                }),
              ]),
            ),
          ),
          SizedBox(height: 12.h),
          Row(children: [
            Text('Less',
                style:
                    GoogleFonts.inter(fontSize: 9.sp, color: AppTheme.secondary)),
            SizedBox(width: 8.w),
            ...List.generate(
              5,
              (i) => Container(
                width: 20.w,
                height: 12.h,
                margin: EdgeInsets.only(right: 2.w),
                decoration: BoxDecoration(
                    color: AppTheme.primaryContainer
                        .withValues(alpha: 0.1 + i * 0.2)),
              ),
            ),
            SizedBox(width: 8.w),
            Text('More',
                style:
                    GoogleFonts.inter(fontSize: 9.sp, color: AppTheme.secondary)),
          ]),
        ],
      ),
    );
  }
}
