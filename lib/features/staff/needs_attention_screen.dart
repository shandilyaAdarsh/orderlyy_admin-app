import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class NeedsAttentionScreen extends StatelessWidget {
  const NeedsAttentionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.secondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'Needs Attention',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '2 Tasks Pending',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          // Cleaning card
          _AttentionCard(
            accentColor: const Color(0xFF64748B),
            tableId: 'T11',
            icon: Icons.cleaning_services_rounded,
            category: 'CLEANING',
            servedAt: 'Served 14 mins ago',
            waitingTime: '14 min wait',
            waitingColor: AppTheme.error,
            actionLabel: 'Mark Clean',
            actionColor: const Color(0xFF64748B),
            isOutlined: true,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 12),

          // Payment card
          _AttentionCard(
            accentColor: const Color(0xFFF59E0B),
            tableId: 'T07',
            icon: Icons.payments_rounded,
            category: 'PAYMENT PENDING',
            servedAt: 'Total: ₹2,340',
            waitingTime: '₹2,340',
            waitingColor: const Color(0xFFD97706),
            actionLabel: 'Process Payment',
            actionColor: AppTheme.primaryContainer,
            isOutlined: false,
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // Intelligence Rail
          _IntelligenceGrid().animate(delay: 200.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final Color accentColor;
  final String tableId;
  final IconData icon;
  final String category;
  final String servedAt;
  final String waitingTime;
  final Color waitingColor;
  final String actionLabel;
  final Color actionColor;
  final bool isOutlined;

  const _AttentionCard({
    required this.accentColor,
    required this.tableId,
    required this.icon,
    required this.category,
    required this.servedAt,
    required this.waitingTime,
    required this.waitingColor,
    required this.actionLabel,
    required this.actionColor,
    required this.isOutlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        border: Border(left: BorderSide(color: accentColor, width: 4)),
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tableId,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Text(
                        category,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    servedAt,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: waitingColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      waitingTime,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: waitingColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: isOutlined
                ? OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: actionColor, width: 2),
                      foregroundColor: actionColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      actionLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      actionLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _IntelligenceGrid extends StatelessWidget {
  const _IntelligenceGrid();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: AppTheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'TURNOVER INTELLIGENCE',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppTheme.secondary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: const [
                _StatCell(
                  label: 'Avg Bussing Time',
                  value: '6.2 min',
                  mono: true,
                ),
                _StatCell(
                  label: 'Avg Checkout Time',
                  value: '4.8 min',
                  mono: true,
                ),
                _StatCell(label: 'Table Efficiency', value: '78%', mono: true),
                _StatCell(label: 'Daily Revenue', value: '₹48.2k', mono: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  const _StatCell({
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: AppTheme.radiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: mono
                ? GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  )
                : GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
          ),
        ],
      ),
    );
  }
}
