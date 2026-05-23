// lib/features/manager/presentation/screens/staff_performance_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class PerfRecord {
  final String staffId;
  final String name;
  final String role;
  final int handledOrders;
  final double avgCompletionMin;
  final double avgResponseSec;
  final double slaRate;
  final int activeTables;
  final String section;

  const PerfRecord({
    required this.staffId,
    required this.name,
    required this.role,
    required this.handledOrders,
    required this.avgCompletionMin,
    required this.avgResponseSec,
    required this.slaRate,
    required this.activeTables,
    required this.section,
  });
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final performanceProvider = StateProvider<List<PerfRecord>>((ref) => const [
      PerfRecord(
        staffId: 's1',
        name: 'Alex J.',
        role: 'Waiter',
        handledOrders: 14,
        avgCompletionMin: 17.2,
        avgResponseSec: 42.0,
        slaRate: 0.92,
        activeTables: 3,
        section: 'Section A',
      ),
      PerfRecord(
        staffId: 's2',
        name: 'Maria K.',
        role: 'Waiter',
        handledOrders: 9,
        avgCompletionMin: 23.5,
        avgResponseSec: 88.0,
        slaRate: 0.74,
        activeTables: 7,
        section: 'Section B',
      ),
      PerfRecord(
        staffId: 's3',
        name: 'David L.',
        role: 'Supervisor',
        handledOrders: 21,
        avgCompletionMin: 15.1,
        avgResponseSec: 31.0,
        slaRate: 0.96,
        activeTables: 2,
        section: 'Bar',
      ),
      PerfRecord(
        staffId: 's4',
        name: 'Priya M.',
        role: 'Waiter',
        handledOrders: 7,
        avgCompletionMin: 19.8,
        avgResponseSec: 55.0,
        slaRate: 0.81,
        activeTables: 4,
        section: 'Section A',
      ),
      PerfRecord(
        staffId: 's5',
        name: 'James R.',
        role: 'Waiter',
        handledOrders: 11,
        avgCompletionMin: 20.3,
        avgResponseSec: 62.0,
        slaRate: 0.78,
        activeTables: 9,
        section: 'Section C',
      ),
    ]);

// ─── Screen ───────────────────────────────────────────────────────────────────

class StaffPerformanceScreen extends ConsumerStatefulWidget {
  const StaffPerformanceScreen({super.key});

  @override
  ConsumerState<StaffPerformanceScreen> createState() => _StaffPerformanceScreenState();
}

class _StaffPerformanceScreenState extends ConsumerState<StaffPerformanceScreen> {
  String _sortBy = 'orders'; // 'orders' | 'sla' | 'name' | 'overload'

  List<PerfRecord> _sortRecords(List<PerfRecord> records) {
    final list = List<PerfRecord>.from(records);
    switch (_sortBy) {
      case 'orders':
        list.sort((a, b) => b.handledOrders.compareTo(a.handledOrders));
        break;
      case 'sla':
        list.sort((a, b) => a.slaRate.compareTo(b.slaRate)); // worst SLA first
        break;
      case 'name':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'overload':
        list.sort((a, b) => b.activeTables.compareTo(a.activeTables)); // most overloaded first
        break;
    }
    return list;
  }

  Color _getSlaColor(double rate) {
    if (rate >= 0.90) return AppColors.success;
    if (rate >= 0.80) return AppColors.warning;
    return AppColors.error;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(performanceProvider);
    final sortedRecords = _sortRecords(records);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Staff Performance',
          style: AppTextStyles.h3.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Shift Context Chip
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule_rounded, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Lunch Service',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Branch Summary KPIs ──────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryKpi('Total Orders', '62', AppColors.primary, textSecondary),
                _buildDivider(borderColor),
                _buildSummaryKpi('Avg Response', '55.6s', AppColors.secondary, textSecondary),
                _buildDivider(borderColor),
                _buildSummaryKpi('Branch SLA', '84%', AppColors.success, textSecondary),
              ],
            ),
          ),

          // ── Sorting Dropdown Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Staff Directory (${sortedRecords.length})',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: textPrimary),
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  icon: const Icon(Icons.sort_rounded, size: 18),
                  elevation: 16,
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: textPrimary),
                  underline: Container(
                    height: 2,
                    color: AppColors.primary,
                  ),
                  onChanged: (String? newValue) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _sortBy = newValue!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 'orders', child: Text('Most Orders')),
                    DropdownMenuItem(value: 'sla', child: Text('Worst SLA')),
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'overload', child: Text('Overloaded First')),
                  ],
                ),
              ],
            ),
          ),

          // ── Staff performance list ───────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: sortedRecords.length,
              itemBuilder: (context, index) {
                final rec = sortedRecords[index];
                return _buildStaffCard(rec, surfaceColor, borderColor, textPrimary, textSecondary);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryKpi(String label, String value, Color color, Color textSecondary) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h2.copyWith(color: color, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: textSecondary),
        ),
      ],
    );
  }

  Widget _buildDivider(Color color) {
    return Container(
      height: 32,
      width: 1,
      color: color,
    );
  }

  Widget _buildStaffCard(
    PerfRecord rec,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isOverloaded = rec.activeTables > 5;
    final isCritical = rec.activeTables > 8;
    final slaColor = _getSlaColor(rec.slaRate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Profile details
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: Center(
                  child: Text(
                    _getInitials(rec.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Name + Role Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          rec.name,
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(width: 8),
                        _buildRoleBadge(rec.role),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rec.section,
                      style: AppTextStyles.caption.copyWith(color: textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              
              // Active Tables Gauge / Icon
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.table_restaurant_rounded, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${rec.activeTables}',
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Metrics List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem('Orders', '${rec.handledOrders}', textSecondary),
              _buildMetricItem('Avg Completion', '${rec.avgCompletionMin.toStringAsFixed(1)} min', textSecondary),
              _buildMetricItem('Call Response', '${rec.avgResponseSec.toInt()}s', textSecondary),
            ],
          ),
          const SizedBox(height: 12),

          // Row 3: SLA compliance bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SLA Compliance',
                          style: AppTextStyles.caption.copyWith(color: textSecondary),
                        ),
                        Text(
                          '${(rec.slaRate * 100).toInt()}%',
                          style: AppTextStyles.caption.copyWith(color: slaColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: rec.slaRate,
                        minHeight: 6,
                        backgroundColor: borderColor,
                        valueColor: AlwaysStoppedAnimation<Color>(slaColor),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Overload badge shown on the right of SLA
              if (isOverloaded) ...[
                const SizedBox(width: 16),
                _buildOverloadBadge(isCritical),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final color = role == 'Supervisor' ? AppColors.secondary : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color textSecondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: textSecondary),
        ),
      ],
    );
  }

  Widget _buildOverloadBadge(bool isCritical) {
    final color = isCritical ? AppColors.error : AppColors.warning;
    final label = isCritical ? 'Critical Load' : 'High Load';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_rounded, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
