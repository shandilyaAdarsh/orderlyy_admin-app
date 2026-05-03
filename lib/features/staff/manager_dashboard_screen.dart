import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        title: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh, shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryFixed, width: 2),
              ),
              child: const Icon(Icons.person_rounded, size: 20, color: AppTheme.secondary),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Good morning, Priya 👋',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
              Text('MANAGER · THE GRAND SPICE',
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500,
                      color: AppTheme.secondary, letterSpacing: 1.2)),
            ]),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined, color: AppTheme.secondary), onPressed: () {}),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text('Orderlli',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Live Banner ──────────────────────────────────────────────────────
          _LiveBanner().animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),
          const SizedBox(height: 20),

          // ── KPI Grid ─────────────────────────────────────────────────────────
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: const [
              _ManagerKpiCard(label: 'Orders Today',   value: '47',   showPriority: false),
              _ManagerKpiCard(label: 'Tables Active',  value: '6/15', showPriority: false),
              _ManagerKpiCard(label: 'Pending Orders', value: '3',    showPriority: true),
              _ManagerKpiCard(label: "Items 86'd Today", value: '2',  showPriority: false),
            ],
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 20),

          // ── Quick Actions ─────────────────────────────────────────────────────
          _SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _QuickAction(icon: Icons.block_rounded, label: '86 Item', errorStyle: true, onTap: () {})),
              const SizedBox(width: 12),
              Expanded(child: _QuickAction(icon: Icons.table_restaurant_rounded, label: 'Tables', onTap: () => context.push('/staff/tables'))),
              const SizedBox(width: 12),
              Expanded(child: _QuickAction(icon: Icons.assignment_rounded, label: 'Orders', onTap: () => context.push('/staff/orders'))),
            ],
          ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 20),

          // ── Live Orders Feed ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionHeader(title: 'Live Orders Feed'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.surfaceContainer, borderRadius: BorderRadius.circular(6)),
                child: Text('Latest first', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppTheme.secondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Order 1 – critical
          _ManagerOrderCard(
            orderId: '#ORD-2841',
            tableInfo: 'Table 12 · 4 Guests',
            timeLabel: '14M AGO',
            urgent: true,
            items: const [('2x Mutton Rogan Josh', 'KITCHEN'), ('1x Garlic Naan Basket', 'READY')],
            showDispatch: true,
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 12),

          // Order 2 – normal
          _ManagerOrderCard(
            orderId: '#ORD-2845',
            tableInfo: 'Table 04 · 2 Guests',
            timeLabel: '2M AGO',
            urgent: false,
            items: const [('1x Paneer Tikka (Appetizer)', ''), ('2x Masala Cola', '')],
            showDispatch: false,
          ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 12),

          // Order 3 – new
          _ManagerOrderCard(
            orderId: '#ORD-2846',
            tableInfo: 'Table 08 · 6 Guests',
            timeLabel: 'JUST NOW',
            urgent: false,
            items: const [],
            showDispatch: false,
            isNew: true,
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

// ── Live Banner ───────────────────────────────────────────────────────────────
class _LiveBanner extends StatelessWidget {
  const _LiveBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
        border: const Border(left: BorderSide(color: AppTheme.error, width: 4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 12, height: 12,
            child: Stack(alignment: Alignment.center, children: [
              Container(width: 12, height: 12,
                  decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle))
                  .animate(onPlay: (c) => c.repeat()).fadeOut(duration: 900.ms),
              Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle)),
            ]),
          ),
          const SizedBox(width: 12),
          Text('LIVE · 4 ACTIVE ORDERS',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppTheme.error, letterSpacing: 1.2)),
        ],
      ),
    );
  }
}

// ── Manager KPI Card ──────────────────────────────────────────────────────────
class _ManagerKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final bool showPriority;
  const _ManagerKpiCard({required this.label, required this.value, required this.showPriority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest, borderRadius: AppTheme.radiusMd,
        border: Border(bottom: BorderSide(color: AppTheme.surfaceContainer, width: 2)),
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
                  color: AppTheme.secondary, letterSpacing: 1.2)),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: GoogleFonts.jetBrainsMono(fontSize: 28, fontWeight: FontWeight.w800,
                      color: showPriority ? AppTheme.primary : AppTheme.onSurface)),
              if (showPriority) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.priority_high_rounded, color: AppTheme.primary, size: 20),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppTheme.primary, width: 4))),
      child: Text(title,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
    );
  }
}

// ── Quick Action ──────────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool errorStyle;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap, this.errorStyle = false});

  @override
  Widget build(BuildContext context) {
    final color = errorStyle ? AppTheme.error : AppTheme.primary;
    return Material(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: AppTheme.radiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.radiusMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Manager Order Card ─────────────────────────────────────────────────────────
class _ManagerOrderCard extends StatelessWidget {
  final String orderId;
  final String tableInfo;
  final String timeLabel;
  final bool urgent;
  final List<(String, String)> items;
  final bool showDispatch;
  final bool isNew;

  const _ManagerOrderCard({
    required this.orderId, required this.tableInfo, required this.timeLabel,
    required this.urgent, required this.items, required this.showDispatch,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = urgent ? AppTheme.error : const Color(0xFF94A3B8);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest, borderRadius: AppTheme.radiusMd,
        border: Border(left: BorderSide(color: accentColor, width: urgent ? 4 : 3)),
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(orderId, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppTheme.secondary)),
              Text(tableInfo,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: (isNew ? AppTheme.primary : (urgent ? AppTheme.error : AppTheme.surfaceContainer)).withValues(alpha: 0.1),
                borderRadius: AppTheme.radiusFull,
              ),
              child: Row(children: [
                if (urgent) ...[Icon(Icons.schedule_rounded, size: 11, color: AppTheme.error), const SizedBox(width: 3)],
                Text(timeLabel,
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800,
                        color: isNew ? AppTheme.primary : (urgent ? AppTheme.error : AppTheme.secondary), letterSpacing: 0.8)),
              ]),
            ),
          ]),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...items.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(i.$1, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.secondary)),
                if (i.$2.isNotEmpty)
                  Text(i.$2, style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
              ]),
            )),
          ] else ...[
            const SizedBox(height: 8),
            Text('Processing items...', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.secondary, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.onSurface,
                    minimumSize: Size.zero,
                    side: BorderSide(color: AppTheme.surfaceContainerHigh),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Details', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                ),
              ),
            ),
            if (showDispatch) ...[
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Dispatch', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  ),
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }
}
