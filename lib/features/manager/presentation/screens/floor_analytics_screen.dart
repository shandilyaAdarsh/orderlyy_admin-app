// lib/features/manager/presentation/screens/floor_analytics_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/sync_state.dart';

// ---------------------------------------------------------------------------
// Inline models & providers
// ---------------------------------------------------------------------------

class AnalyticsSnapshot {
  final int activeTables;
  final int totalTables;
  final double occupancyRate;
  final double avgTicketMinutes;
  final int delayedCount;
  final double slaRate;
  final int pendingPayments;
  final int kitchenBacklog;
  final DateTime updatedAt;

  const AnalyticsSnapshot({
    required this.activeTables,
    required this.totalTables,
    required this.occupancyRate,
    required this.avgTicketMinutes,
    required this.delayedCount,
    required this.slaRate,
    required this.pendingPayments,
    required this.kitchenBacklog,
    required this.updatedAt,
  });

  AnalyticsSnapshot copyWith({
    int? activeTables,
    int? totalTables,
    double? occupancyRate,
    double? avgTicketMinutes,
    int? delayedCount,
    double? slaRate,
    int? pendingPayments,
    int? kitchenBacklog,
    DateTime? updatedAt,
  }) {
    return AnalyticsSnapshot(
      activeTables: activeTables ?? this.activeTables,
      totalTables: totalTables ?? this.totalTables,
      occupancyRate: occupancyRate ?? this.occupancyRate,
      avgTicketMinutes: avgTicketMinutes ?? this.avgTicketMinutes,
      delayedCount: delayedCount ?? this.delayedCount,
      slaRate: slaRate ?? this.slaRate,
      pendingPayments: pendingPayments ?? this.pendingPayments,
      kitchenBacklog: kitchenBacklog ?? this.kitchenBacklog,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

final analyticsProvider = StateProvider<AnalyticsSnapshot>((ref) => AnalyticsSnapshot(
  activeTables: 14,
  totalTables: 20,
  occupancyRate: 0.70,
  avgTicketMinutes: 18.0,
  delayedCount: 3,
  slaRate: 0.87,
  pendingPayments: 2,
  kitchenBacklog: 4,
  updatedAt: DateTime.now(),
));

final _syncStateProvider = StateProvider<SyncState>((ref) => SyncState.fresh);

// ---------------------------------------------------------------------------
// Mock heatmap data: 20 tables
// 'available'=green, 'occupied'=amber, 'delayed'=red, 'paying'=purple
// ---------------------------------------------------------------------------
enum _TableState { available, occupied, delayed, paying }

const _mockTableStates = [
  _TableState.occupied,  // 1
  _TableState.available, // 2
  _TableState.delayed,   // 3
  _TableState.occupied,  // 4
  _TableState.paying,    // 5
  _TableState.occupied,  // 6
  _TableState.delayed,   // 7
  _TableState.available, // 8
  _TableState.occupied,  // 9
  _TableState.paying,    // 10
  _TableState.available, // 11
  _TableState.occupied,  // 12
  _TableState.delayed,   // 13
  _TableState.occupied,  // 14
  _TableState.available, // 15
  _TableState.occupied,  // 16
  _TableState.available, // 17
  _TableState.occupied,  // 18
  _TableState.occupied,  // 19
  _TableState.available, // 20
];

Color _tableColor(_TableState state) {
  switch (state) {
    case _TableState.available:
      return AppColors.success;
    case _TableState.occupied:
      return AppColors.warning;
    case _TableState.delayed:
      return AppColors.error;
    case _TableState.paying:
      return const Color(0xFF8B5CF6);
  }
}

// ---------------------------------------------------------------------------
// SLA Gauge Painter
// ---------------------------------------------------------------------------
class _SlaGaugePainter extends CustomPainter {
  final double value; // 0.0–1.0
  final Color color;

  const _SlaGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;

    // Track
    final trackPaint = Paint()
      ..color = AppColors.darkBorder
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      trackPaint,
    );

    // Progress
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5 * value.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_SlaGaugePainter old) =>
      old.value != value || old.color != color;
}

// ---------------------------------------------------------------------------
// Main Screen
// ---------------------------------------------------------------------------
class FloorAnalyticsScreen extends ConsumerStatefulWidget {
  const FloorAnalyticsScreen({super.key});

  @override
  ConsumerState<FloorAnalyticsScreen> createState() =>
      _FloorAnalyticsScreenState();
}

class _FloorAnalyticsScreenState extends ConsumerState<FloorAnalyticsScreen> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    ref.read(analyticsProvider.notifier).update(
          (s) => s.copyWith(updatedAt: DateTime.now()),
        );
    if (mounted) setState(() => _isRefreshing = false);
  }


  Color _slaColor(double rate) {
    if (rate < 0.70) return AppColors.error;
    if (rate < 0.85) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(analyticsProvider);
    final syncState = ref.watch(_syncStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Floor Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          _SyncStateChip(state: syncState),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _handleRefresh,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _ShiftSubtitle(textSecondary: textSecondary),
              ),
            ),

            // ── KPI chips row ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _KpiRow(snap: snap, onDelayedTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${snap.delayedCount} table(s) delayed: Table 3, Table 7, Table 13',
                    ),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Heatmap card ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HeatmapCard(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  textSecondary: textSecondary,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── SLA Performance ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SlaSection(
                  slaRate: snap.slaRate,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  textSecondary: textSecondary,
                  slaColor: _slaColor(snap.slaRate),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Bottleneck section ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _BottleneckSection(
                  snap: snap,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Footer ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: Text(
                    'Last updated: ${_isRefreshing ? 'refreshing…' : 'just now'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SyncState chip
// ---------------------------------------------------------------------------
class _SyncStateChip extends StatelessWidget {
  final SyncState state;
  const _SyncStateChip({required this.state});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (state) {
      case SyncState.fresh:
        color = AppColors.success;
        label = 'LIVE';
      case SyncState.stale:
        color = AppColors.warning;
        label = 'STALE';
      case SyncState.replaying:
        color = AppColors.secondary;
        label = 'SYNCING';
      case SyncState.degraded:
        color = AppColors.error;
        label = 'OFFLINE';
      case SyncState.unknown:
        color = Colors.grey;
        label = '—';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shift subtitle
// ---------------------------------------------------------------------------
class _ShiftSubtitle extends StatelessWidget {
  final Color textSecondary;
  const _ShiftSubtitle({required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 14, color: textSecondary),
        const SizedBox(width: 4),
        Text(
          'Lunch Service · 2h 14m active',
          style: TextStyle(fontSize: 12, color: textSecondary),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// KPI Row
// ---------------------------------------------------------------------------
class _KpiRow extends StatelessWidget {
  final AnalyticsSnapshot snap;
  final VoidCallback onDelayedTap;

  const _KpiRow({required this.snap, required this.onDelayedTap});

  Color _occupancyColor(double rate) {
    if (rate >= 0.85) return AppColors.error;
    if (rate >= 0.70) return AppColors.warning;
    return AppColors.success;
  }

  Color _avgTicketColor(double min) {
    if (min >= 30) return AppColors.error;
    if (min >= 20) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _KpiChip(
        label: 'Active Tables',
        value: '${snap.activeTables} / ${snap.totalTables}',
        color: AppColors.primary,
        icon: Icons.table_restaurant_rounded,
      ),
      _KpiChip(
        label: 'Occupancy',
        value: '${(snap.occupancyRate * 100).toInt()}%',
        color: _occupancyColor(snap.occupancyRate),
        icon: Icons.people_alt_rounded,
      ),
      _KpiChip(
        label: 'Avg Ticket',
        value: '${snap.avgTicketMinutes.toInt()} min',
        color: _avgTicketColor(snap.avgTicketMinutes),
        icon: Icons.timer_rounded,
      ),
      GestureDetector(
        onTap: onDelayedTap,
        child: _KpiChip(
          label: 'Delayed',
          value: '${snap.delayedCount}',
          color: snap.delayedCount > 0 ? AppColors.error : AppColors.success,
          icon: Icons.warning_rounded,
          tappable: true,
        ),
      ),
      _KpiChip(
        label: 'Pending Bills',
        value: '${snap.pendingPayments}',
        color: const Color(0xFF8B5CF6),
        icon: Icons.receipt_long_rounded,
      ),
    ];

    return SizedBox(
      height: 88,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool tappable;

  const _KpiChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.tappable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              if (tappable) ...[
                const Spacer(),
                Icon(Icons.touch_app_rounded,
                    size: 11, color: color.withValues(alpha: 0.6)),
              ],
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Heatmap card
// ---------------------------------------------------------------------------
class _HeatmapCard extends StatelessWidget {
  final Color surfaceColor;
  final Color borderColor;
  final Color textSecondary;

  const _HeatmapCard({
    required this.surfaceColor,
    required this.borderColor,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FLOOR HEATMAP',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.8,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          // 4 columns × 5 rows = 20 cells
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.4,
            ),
            itemCount: 20,
            itemBuilder: (_, i) {
              final tableState = _mockTableStates[i];
              final color = _tableColor(tableState);
              return Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      _stateLabel(tableState),
                      style: TextStyle(
                        fontSize: 8,
                        color: color.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Legend
          const Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendDot(color: AppColors.success, label: 'Available'),
              _LegendDot(color: AppColors.warning, label: 'Occupied'),
              _LegendDot(color: AppColors.error, label: 'Delayed'),
              _LegendDot(
                  color: Color(0xFF8B5CF6), label: 'Paying'),
            ],
          ),
        ],
      ),
    );
  }

  String _stateLabel(_TableState state) {
    switch (state) {
      case _TableState.available:
        return 'Free';
      case _TableState.occupied:
        return 'Busy';
      case _TableState.delayed:
        return 'Late';
      case _TableState.paying:
        return 'Pay';
    }
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// SLA section
// ---------------------------------------------------------------------------
class _SlaSection extends StatelessWidget {
  final double slaRate;
  final Color surfaceColor;
  final Color borderColor;
  final Color textSecondary;
  final Color slaColor;

  const _SlaSection({
    required this.slaRate,
    required this.surfaceColor,
    required this.borderColor,
    required this.textSecondary,
    required this.slaColor,
  });

  @override
  Widget build(BuildContext context) {
    final breachedTables = [
      ('Table 3', AppColors.error),
      ('Table 7', AppColors.error),
      ('Table 13', AppColors.warning),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SLA PERFORMANCE',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.8,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Gauge
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(120, 120),
                      painter: _SlaGaugePainter(
                        value: slaRate,
                        color: slaColor,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(slaRate * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: slaColor,
                          ),
                        ),
                        Text(
                          'SLA Rate',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SLA Breach List',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: breachedTables
                          .map(
                            (t) => Chip(
                              label: Text(
                                t.$1,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: t.$2,
                                ),
                              ),
                              backgroundColor:
                                  t.$2.withValues(alpha: 0.12),
                              side: BorderSide(
                                  color: t.$2.withValues(alpha: 0.35)),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottleneck section
// ---------------------------------------------------------------------------
class _BottleneckSection extends StatelessWidget {
  final AnalyticsSnapshot snap;
  final Color surfaceColor;
  final Color borderColor;

  const _BottleneckSection({
    required this.snap,
    required this.surfaceColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BOTTLENECKS',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.8,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          _BottleneckRow(
            icon: Icons.restaurant_menu_rounded,
            label: 'Kitchen Backlog',
            value:
                '${snap.kitchenBacklog} orders > 15 min',
            color: AppColors.error,
          ),
          const SizedBox(height: 10),
          _BottleneckRow(
            icon: Icons.receipt_long_rounded,
            label: 'Pending Payment',
            value:
                '${snap.pendingPayments} tables > 10 min',
            color: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }
}

class _BottleneckRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _BottleneckRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
