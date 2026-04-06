import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

// ── Table Status ──────────────────────────────────────────────────────────────
enum TableStatus { vacant, occupied, payment, cleaning }

class TableData {
  final String id;
  final TableStatus status;
  final int capacity;
  final String? timer;
  final String? billAmount;

  const TableData({
    required this.id,
    required this.status,
    this.capacity = 4,
    this.timer,
    this.billAmount,
  });
}

class StaffTablesScreen extends StatefulWidget {
  const StaffTablesScreen({super.key});

  @override
  State<StaffTablesScreen> createState() => _StaffTablesScreenState();
}

class _StaffTablesScreenState extends State<StaffTablesScreen> {
  int _navIndex = 0;

  static const _tables = [
    TableData(id: 'T01', status: TableStatus.vacant, capacity: 4),
    TableData(id: 'T02', status: TableStatus.occupied, capacity: 4, timer: '24:10', billAmount: '₹2,410'),
    TableData(id: 'T03', status: TableStatus.payment, capacity: 2, billAmount: '₹1,850'),
    TableData(id: 'T04', status: TableStatus.cleaning, capacity: 4),
    TableData(id: 'T05', status: TableStatus.vacant, capacity: 6),
    TableData(id: 'T06', status: TableStatus.occupied, capacity: 6, timer: '58:45', billAmount: '₹4,200'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Top App Bar ───────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: AppTheme.surfaceContainerLowest,
                elevation: 0,
                shadowColor: const Color(0x149D0518),
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    Text(
                      'TableOS',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 20,
                      color: AppTheme.surfaceContainerHighest,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Floor Map',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          '15 TABLES',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.secondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppTheme.secondary),
                    onPressed: () {},
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      child: Icon(Icons.person_rounded, size: 18, color: AppTheme.secondary),
                    ),
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Legend ──────────────────────────────────────────────
                    _buildLegend(),
                    const SizedBox(height: 20),

                    // ── Table Grid ──────────────────────────────────────────
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: _tables.length,
                      itemBuilder: (context, i) {
                        return _TableCard(table: _tables[i])
                            .animate(delay: Duration(milliseconds: 60 * i))
                            .fadeIn(duration: 350.ms)
                            .slideY(begin: 0.15, curve: Curves.easeOut);
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Floor Intelligence Bento ─────────────────────────────
                    _buildFloorIntelligence(),
                    const SizedBox(height: 16),

                    // ── Add Temp Table ───────────────────────────────────────
                    _buildAddTempTable(),
                    const SizedBox(height: 96),
                  ]),
                ),
              ),
            ],
          ),

          // ── FAB ─────────────────────────────────────────────────────────────
          Positioned(
            bottom: 88,
            right: 16,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.crimsonShadow,
                ),
                child: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
              ),
            ).animate(delay: 400.ms).scale(
                  begin: const Offset(0, 0),
                  curve: Curves.easeOutBack,
                ),
          ),

          // ── Bottom Nav ──────────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _StaffBottomNav(
              currentIndex: _navIndex,
              onTap: (i) {
                setState(() => _navIndex = i);
                if (i == 1) context.push('/staff/orders');
                if (i == 2) context.push('/staff/inventory');
                if (i == 4) context.push('/admin/settings');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    const items = [
      (color: Color(0xFF059669), label: 'Vacant'),
      (color: AppTheme.primaryContainer, label: 'Occupied'),
      (color: Color(0xFFD97706), label: 'Payment'),
      (color: Color(0xFF94A3B8), label: 'Cleaning'),
    ];
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.secondary),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFloorIntelligence() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: AppTheme.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FLOOR INTELLIGENCE',
            style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: AppTheme.secondary, letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Stats grid
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _IntelligenceStat(label: 'Turnover Rate', value: '1.2h')),
                    const SizedBox(width: 12),
                    Expanded(child: _IntelligenceStat(label: 'Avg Bill', value: '₹2.8k')),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Top table card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: AppTheme.radiusSm,
                    border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Top Table Today',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
                          Text('+12%',
                              style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.w500, color: const Color(0xFF059669))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('T02',
                                  style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('₹18,450 Total',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
                              Text('6 Sessions Served',
                                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.secondary)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildAddTempTable() {
    return InkWell(
      onTap: () {},
      borderRadius: AppTheme.radiusMd,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0x08059669),
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: const Color(0x40059669), width: 2, style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF059669), size: 28),
              const SizedBox(height: 4),
              Text(
                'ADD TEMP TABLE',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.secondary, letterSpacing: 1.5),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: 350.ms).fadeIn(duration: 400.ms);
  }
}

// ── Table Card ────────────────────────────────────────────────────────────────
class _TableCard extends StatelessWidget {
  final TableData table;
  const _TableCard({required this.table});

  Color get _statusColor {
    return switch (table.status) {
      TableStatus.vacant   => const Color(0xFF059669),
      TableStatus.occupied => AppTheme.primaryContainer,
      TableStatus.payment  => const Color(0xFFD97706),
      TableStatus.cleaning => const Color(0xFF94A3B8),
    };
  }

  String get _statusLabel {
    return switch (table.status) {
      TableStatus.vacant   => 'VACANT',
      TableStatus.occupied => 'OCCUPIED',
      TableStatus.payment  => 'PAYMENT',
      TableStatus.cleaning => 'CLEANING',
    };
  }

  Color get _bgColor {
    return switch (table.status) {
      TableStatus.vacant   => AppTheme.surfaceContainerLowest,
      TableStatus.occupied => const Color(0x08C0272D),
      TableStatus.payment  => const Color(0x08D97706),
      TableStatus.cleaning => const Color(0x0894A3B8),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isOccupied = table.status == TableStatus.occupied;
    final isPayment  = table.status == TableStatus.payment;
    final isCleaning = table.status == TableStatus.cleaning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: AppTheme.radiusMd,
        border: isOccupied
            ? Border.all(color: _statusColor, width: 2)
            : Border.all(color: _statusColor.withValues(alpha: 0.4), width: 1),
        boxShadow: isOccupied ? AppTheme.crimsonShadowLight : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table ID
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    table.id,
                    style: GoogleFonts.inter(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: isCleaning ? AppTheme.secondary : AppTheme.onSurface,
                    ),
                  ),
                  if (isOccupied)
                    Row(
                      children: [
                        Icon(Icons.timer_rounded, size: 12, color: _statusColor),
                        const SizedBox(width: 3),
                        Text(table.timer!,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor,
                            )),
                      ],
                    )
                  else if (isCleaning)
                    Text('Ready soon',
                        style: GoogleFonts.jetBrainsMono(fontSize: 10, color: const Color(0xFF94A3B8)))
                  else
                    Row(
                      children: [
                        Icon(Icons.group_rounded, size: 12, color: AppTheme.secondary),
                        const SizedBox(width: 3),
                        Text('${table.capacity}',
                            style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppTheme.secondary)),
                      ],
                    ),
                ],
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: AppTheme.radiusFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 5, height: 5, decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(_statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 8, fontWeight: FontWeight.w800,
                          color: _statusColor, letterSpacing: 0.8,
                        )),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // Bottom row
          Divider(color: _statusColor.withValues(alpha: 0.12), thickness: 1),
          const SizedBox(height: 8),
          if (isOccupied || isPayment) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPayment ? 'PENDING' : 'TOTAL BILL',
                      style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.secondary, letterSpacing: 1),
                    ),
                    Text(
                      table.billAmount!,
                      style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.w700, color: _statusColor),
                    ),
                  ],
                ),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _statusColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text(
                      isPayment ? 'Settle' : 'Details',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isCleaning)
            SizedBox(
              height: 32,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: _statusColor.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Mark Clean',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.secondary)),
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child: Text('Assign Table',
                    style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppTheme.primary, letterSpacing: 0.5,
                    )),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Floor Intelligence Stat ───────────────────────────────────────────────────
class _IntelligenceStat extends StatelessWidget {
  final String label;
  final String value;
  const _IntelligenceStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppTheme.secondary)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.primaryContainer)),
        ],
      ),
    );
  }
}

// ── Staff Bottom Nav ────────────────────────────────────────────────────────
class _StaffBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _StaffBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Icons.layers_rounded, label: 'Floor'),
      (icon: Icons.restaurant_menu_rounded, label: 'Orders'),
      (icon: Icons.inventory_2_rounded, label: 'Inventory'),
      (icon: Icons.bar_chart_rounded, label: 'Metrics'),
      (icon: Icons.settings_rounded, label: 'Settings'),
    ];
    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: Color(0xCCFFFFFF),
        boxShadow: [BoxShadow(color: Color(0x0D9D0518), blurRadius: 24, offset: Offset(0, -8))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final active = currentIndex == i;
            final item = items[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.primary.withValues(alpha: 0.06) : Colors.transparent,
                    border: active ? const Border(left: BorderSide(color: AppTheme.primaryContainer, width: 3)) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon,
                          color: active ? AppTheme.primaryContainer : AppTheme.secondary,
                          size: 22),
                      const SizedBox(height: 2),
                      Text(item.label,
                          style: GoogleFonts.inter(
                            fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.8,
                            color: active ? AppTheme.primaryContainer : AppTheme.secondary,
                          )),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
