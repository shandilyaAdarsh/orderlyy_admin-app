import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _periodIndex = 0;
  static const _periods = ['TODAY', 'WEEK', 'MONTH'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 64.h,
        title: Text(
          'Orderlli',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
            color: AppTheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: AppTheme.secondary,
              size: 24.r,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 100.h),
        children: [
          // Title + filter pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Analytics',
                  style: GoogleFonts.inter(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Row(
                children: List.generate(_periods.length, (i) {
                  final active = _periodIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _periodIndex = i),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      margin: EdgeInsets.only(left: 6.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 7.h,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.primaryContainer
                            : AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        _periods[i],
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : AppTheme.secondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Revenue chart
          const _RevenueChart().animate().fadeIn(duration: 400.ms),
          SizedBox(height: 16.h),

          // KPI horizontal scroll
          const _KpiStrip().animate(delay: 100.ms).fadeIn(duration: 400.ms),
          SizedBox(height: 24.h),

          // Best Sellers
          const _BestSellersCard().animate(delay: 150.ms).fadeIn(duration: 400.ms),
          SizedBox(height: 16.h),

          // Station Distribution
          const _StationDonutCard().animate(delay: 200.ms).fadeIn(duration: 400.ms),
          SizedBox(height: 16.h),

          // Peak Hours Heatmap
          const _PeakHoursCard().animate(delay: 250.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

// ── Revenue Chart ─────────────────────────────────────────────────────────────
class _RevenueChart extends StatelessWidget {
  const _RevenueChart();

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
                    Text(
                      'Revenue Today',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '₹48,240',
                      style: GoogleFonts.inter(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: const Color(0xFF059669),
                      size: 14.r,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '+12.4%',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 140.h,
            child: CustomPaint(painter: _RevenuePainter(), size: Size.infinite),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final h in [
                '8AM',
                '10AM',
                '12PM',
                '2PM',
                '4PM',
                '6PM',
                '8PM',
              ])
                Text(
                  h,
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: AppTheme.secondary,
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

    fillPath
      ..lineTo(w, h)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x22C0272D), Color(0x00C0272D)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppTheme.primaryContainer
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Draw dots
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

// ── KPI Strip ─────────────────────────────────────────────────────────────────
class _KpiStrip extends StatelessWidget {
  const _KpiStrip();

  @override
  Widget build(BuildContext context) {
    const kpis = [
      ('Revenue', '₹48,240', '+12.4%', true),
      ('Orders', '147', '+8.1%', true),
      ('Avg Order', '₹328', '-2.3%', false),
      ('Turnover', '1.8x', '+0.3x', true),
    ];
    return SizedBox(
      height: 125.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kpis.length,
        separatorBuilder: (context, index) => SizedBox(width: 12.w),
        itemBuilder: (context, i) {
          final (label, value, delta, positive) = kpis[i];
          return Container(
            width: 130.w,
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: AppTheme.radiusMd,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.surfaceContainerHigh,
                  width: 2.h,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  delta,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: positive ? const Color(0xFF059669) : AppTheme.error,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Best Sellers ──────────────────────────────────────────────────────────────
class _BestSellersCard extends StatelessWidget {
  const _BestSellersCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Mutton Rogan Josh', 0.92, '147 orders'),
      ('Paneer Tikka', 0.78, '124 orders'),
      ('Garlic Naan', 0.71, '113 orders'),
      ('Mango Lassi', 0.58, '93 orders'),
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
          Text(
            'Best Sellers',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(height: 20.h),
          ...List.generate(items.length, (i) {
            final (name, ratio, orders) = items[i];
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        orders,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11.sp,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999.r),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: AppTheme.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryContainer.withValues(
                          alpha: 0.5 + 0.5 * ratio,
                        ),
                      ),
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

// ── Station Donut ─────────────────────────────────────────────────────────────
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
          Text(
            'Station Distribution',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              SizedBox(
                width: 130.r,
                height: 130.r,
                child: CustomPaint(
                  painter: _DonutPainter(
                    stations.map((s) => (s.$2, s.$3)).toList(),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '147',
                          style: GoogleFonts.inter(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          'ORDERS',
                          style: GoogleFonts.inter(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.secondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  children: stations
                      .map(
                        (s) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10.r,
                                      height: 10.r,
                                      decoration: BoxDecoration(
                                        color: s.$3,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        s.$1,
                                        style: GoogleFonts.inter(
                                          fontSize: 12.sp,
                                          color: AppTheme.secondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                '${(s.$2 * 100).toInt()}%',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
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

// ── Peak Hours Heatmap ────────────────────────────────────────────────────────
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
          Text(
            'Peak Hours',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Order density by hour and day',
            style: GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.secondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 20.h),
          // Hour labels
          Padding(
            padding: EdgeInsets.only(left: 36.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _hours
                  .map(
                    (h) => Text(
                      h,
                      style: GoogleFonts.inter(
                        fontSize: 8.sp,
                        color: AppTheme.secondary,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          SizedBox(height: 8.h),
          // Grid
          ...List.generate(
            _days.length,
            (row) => Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 30.w,
                    child: Text(
                      _days[row],
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
                  ...List.generate(_hours.length, (col) {
                    final v = _heat[row][col];
                    return Expanded(
                      child: Container(
                        height: 22.h,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withValues(
                            alpha: v * 0.85 + 0.05,
                          ),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          // Legend
          Row(
            children: [
              Text(
                'Less',
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: AppTheme.secondary,
                ),
              ),
              SizedBox(width: 8.w),
              ...List.generate(
                5,
                (i) => Container(
                  width: 20.w,
                  height: 12.h,
                  margin: EdgeInsets.only(right: 2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withValues(
                      alpha: 0.1 + i * 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'More',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
