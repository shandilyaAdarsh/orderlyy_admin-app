import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  int _filterIndex = 0;
  static const _filters = ['ALL', 'PENDING', 'COOKING', 'READY', 'SERVED'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.surfaceContainerLowest,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: Row(children: [
              Text('TableOS',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary)),
              const SizedBox(width: 12),
              Container(width: 1, height: 20, color: AppTheme.surfaceContainerHighest),
              const SizedBox(width: 12),
              Text('Live Orders',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
                child: Text('4', style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ]),
            actions: [
              IconButton(icon: const Icon(Icons.notifications_outlined, color: AppTheme.secondary), onPressed: () {}),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_filters.length, (i) {
                      final active = _filterIndex == i;
                      return GestureDetector(
                        onTap: () => setState(() => _filterIndex = i),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? AppTheme.primaryContainer : AppTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_filters[i],
                              style: GoogleFonts.inter(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: active ? Colors.white : AppTheme.secondary, letterSpacing: 0.8,
                              )),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Urgent order card
                _UrgentOrderCard().animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 12),

                // Normal order card
                _NormalOrderCard().animate(delay: 80.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 12),

                // Intelligence rail
                _IntelligenceRail().animate(delay: 150.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 12),

                // Kitchen spike alert
                _KitchenSpikeCard().animate(delay: 200.ms).fadeIn(duration: 400.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Urgent Order Card ─────────────────────────────────────────────────────────
class _UrgentOrderCard extends StatelessWidget {
  const _UrgentOrderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        border: const Border(left: BorderSide(color: AppTheme.primaryContainer, width: 4)),
        boxShadow: AppTheme.crimsonShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('TABLE 12 · #ORD-2841',
                        style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppTheme.secondary, letterSpacing: 0.8)),
                    Text('Ananya M. · 4 Guests',
                        style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.schedule_rounded, size: 12, color: AppTheme.error),
                      const SizedBox(width: 4),
                      Text('14M AGO',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.error, letterSpacing: 0.8)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                // Items
                for (final (item, station, status, statusColor) in [
                  ('Mutton Rogan Josh', 'TANDOOR STATION', 'COOKING', AppTheme.primaryContainer),
                  ('Garlic Naan Basket', 'BREAD STATION',  'READY',   const Color(0xFF059669)),
                  ('Mango Lassi × 2',   'BAR',             'PENDING',  AppTheme.surfaceDim),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.onSurface)),
                        Text(station, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppTheme.secondary, letterSpacing: 0.5)),
                      ]),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(status,
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5)),
                      ),
                    ]),
                  ),
                const SizedBox(height: 12),

                // Allergy banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 16),
                    const SizedBox(width: 8),
                    Text('NUT ALLERGY — Ananya M. · Check dish prep carefully',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF78350F))),
                  ]),
                ),
                const SizedBox(height: 12),

                // Kitchen note
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Note: Rogan josh, extra gravy, mild heat. Naan — no butter.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.secondary,
                          fontStyle: FontStyle.italic)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Accept button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {},
                child: Text('ACCEPT ORDER',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Normal Order Card ─────────────────────────────────────────────────────────
class _NormalOrderCard extends StatelessWidget {
  const _NormalOrderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        border: const Border(left: BorderSide(color: Color(0xFF94A3B8), width: 4)),
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TABLE 08 · #ORD-2839',
                  style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppTheme.secondary)),
              Text('Served · 6 Guests',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: AppTheme.surfaceContainer, borderRadius: BorderRadius.circular(8)),
              child: Text('45M AGO',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.secondary, letterSpacing: 0.8)),
            ),
          ]),
          const SizedBox(height: 12),
          ...['Sea Bass Ceviche × 1', 'Wagyu Burger × 2', 'House Salad × 1'].map((item) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.radio_button_unchecked, size: 12, color: AppTheme.surfaceDim),
                const SizedBox(width: 10),
                Text(item, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.secondary)),
              ]),
            )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.surfaceContainerHigh),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('VIEW DETAILS',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppTheme.secondary, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Intelligence Rail ─────────────────────────────────────────────────────────
class _IntelligenceRail extends StatelessWidget {
  const _IntelligenceRail();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: AppTheme.radiusMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KITCHEN INTELLIGENCE',
              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B), letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _RailStat(label: 'Avg Prep Time', value: '14m', good: true)),
            const SizedBox(width: 12),
            Expanded(child: _RailStat(label: 'Queue Density', value: '72%', good: false)),
            const SizedBox(width: 12),
            Expanded(child: _RailStat(label: 'Active Tables', value: '6/15', good: true)),
          ]),
        ],
      ),
    );
  }
}

class _RailStat extends StatelessWidget {
  final String label;
  final String value;
  final bool good;
  const _RailStat({required this.label, required this.value, required this.good});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: const Color(0xFF64748B))),
      const SizedBox(height: 4),
      Text(value,
          style: GoogleFonts.jetBrainsMono(fontSize: 20, fontWeight: FontWeight.w700,
              color: good ? const Color(0xFF34D399) : const Color(0xFFFB923C))),
    ]);
  }
}

// ── Kitchen Spike Alert ────────────────────────────────────────────────────────
class _KitchenSpikeCard extends StatelessWidget {
  const _KitchenSpikeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryContainer, Color(0xFF9B1C1C)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.crimsonShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('KITCHEN SPIKE ALERT',
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.7), letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text('6 orders incoming',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('Call in extra grill cook NOW',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
          ]),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}
