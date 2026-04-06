import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../orders/admin_orders_screen.dart';
import '../staff/staff_tables_screen.dart';
import '../menu/menu_management_screen.dart';

// ── Bottom Nav State ──────────────────────────────────────────────────────────
final _currentNavIndexProvider = StateProvider<int>((ref) => 0);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(_currentNavIndexProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: navIndex,
        children: const [
          _DashboardHome(),
          AdminOrdersScreen(),
          StaffTablesScreen(),
          MenuManagementScreen(),
          _MoreTab(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: navIndex,
        onTap: (i) => ref.read(_currentNavIndexProvider.notifier).state = i,
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.dashboard_rounded, label: 'Home'),
      _NavItem(icon: Icons.receipt_long_rounded, label: 'Orders'),
      _NavItem(icon: Icons.deck_rounded, label: 'Tables'),
      _NavItem(icon: Icons.restaurant_rounded, label: 'Menu'),
      _NavItem(icon: Icons.more_horiz_rounded, label: 'More'),
    ];

    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      color: active
                          ? AppTheme.primaryContainer
                          : AppTheme.secondary,
                      size: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? AppTheme.primaryContainer
                            : AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Active dot
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: active ? 4 : 0,
                      height: active ? 4 : 0,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ── More Tab (quick links to Analytics, Staff, Inventory, Profile) ────────────
class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    final links = [
      (
        icon: Icons.bar_chart_rounded,
        label: 'Analytics',
        route: '/admin/analytics',
        color: const Color(0xFF7C3AED),
      ),
      (
        icon: Icons.group_rounded,
        label: 'Staff',
        route: '/admin/staff',
        color: const Color(0xFF2563EB),
      ),
      (
        icon: Icons.inventory_2_rounded,
        label: 'Inventory',
        route: '/admin/inventory',
        color: const Color(0xFF059669),
      ),
      (
        icon: Icons.person_rounded,
        label: 'Profile',
        route: '/admin/profile',
        color: const Color(0xFFC0272D),
      ),
      (
        icon: Icons.settings_rounded,
        label: 'Settings',
        route: '/admin/settings',
        color: const Color(0xFF64748B),
      ),
    ];
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'More',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...links.map(
            (link) =>
                GestureDetector(
                      onTap: () => context.push(link.route),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: AppTheme.radiusMd,
                          border: Border.all(
                            color: AppTheme.surfaceContainerHigh,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: link.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                link.icon,
                                color: link.color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              link.label,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.secondary,
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate(
                      delay: Duration(milliseconds: 50 * links.indexOf(link)),
                    )
                    .fadeIn(duration: 300.ms),
          ),
        ],
      ),
    );
  }
}

// ── Dashboard Home Tab ────────────────────────────────────────────────────────
class _DashboardHome extends ConsumerStatefulWidget {
  const _DashboardHome();

  @override
  ConsumerState<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends ConsumerState<_DashboardHome> {
  late String _timeString;

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    final now = DateTime.now();
    _timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) setState(_updateTime);
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final List<_QuickAction> quickActions = [
      const _QuickAction(icon: Icons.block_rounded, label: '86 LIST'),
      const _QuickAction(icon: Icons.group_rounded, label: 'STAFF'),
      const _QuickAction(icon: Icons.qr_code_2_rounded, label: 'QR'),
      const _QuickAction(icon: Icons.query_stats_rounded, label: 'STATS'),
    ];
    final List<_KpiData> kpis = [
      _KpiData(
        label: 'Revenue Today',
        value: '₹24,680',
        delta: '↑ 12% vs yest.',
        deltaPositive: true,
        showSparkline: true,
      ),
      _KpiData(
        label: 'Total Orders',
        value: '47',
        delta: '↑ 8 more today',
        deltaPositive: true,
      ),
      _KpiData(
        label: 'Avg Order Value',
        value: '₹524',
        showBar: true,
        barValue: 0.65,
      ),
      _KpiData(
        label: 'Tables Active',
        value: '6 / 15',
        showDots: true,
        activeDots: 6,
        totalDots: 8,
      ),
    ];

    return CustomScrollView(
      slivers: [
        // ── Top App Bar ─────────────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          backgroundColor: AppTheme.surfaceContainerLowest,
          elevation: 1,
          shadowColor: AppTheme.surfaceContainerHigh,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.surfaceContainer,
                child: Text(
                  (user?.email?.isNotEmpty == true)
                      ? user!.email![0].toUpperCase()
                      : 'A',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_greeting, Admin',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    'The Grand Spice',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_rounded,
                    color: AppTheme.secondary,
                    size: 24,
                  ),
                  onPressed: () {},
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.surfaceContainerLowest,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Live Banner ──────────────────────────────────────────────
              _buildLiveBanner(),
              const SizedBox(height: 20),

              // ── KPI Grid ─────────────────────────────────────────────────
              _buildSectionHeader('Overview'),
              const SizedBox(height: 12),
              _buildKpiGrid(kpis),
              const SizedBox(height: 20),

              // ── Live Orders ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Live Orders'),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: Text(
                      'See All',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryContainer,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryContainer,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildOrderCard(),
              const SizedBox(height: 20),

              // ── Quick Actions ─────────────────────────────────────────────
              _buildQuickActions(quickActions),
              const SizedBox(height: 24),

              // Sign-out row
              TextButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/role-select');
                },
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('Sign out'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x08C0272D), // 5% crimson tint
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: const Border(
          left: BorderSide(color: AppTheme.primaryContainer, width: 3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Pulsing dot
              SizedBox(
                width: 12,
                height: 12,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .fadeOut(duration: 900.ms, curve: Curves.easeOut),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'LIVE · 4 active orders',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryContainer,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          Text(
            _timeString,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.secondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05);
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.onSurface,
      ),
    );
  }

  Widget _buildKpiGrid(List<_KpiData> kpis) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, i) {
        return _KpiCard(data: kpis[i])
            .animate(delay: Duration(milliseconds: 100 * i))
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.15, curve: Curves.easeOut);
      },
    );
  }

  Widget _buildOrderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        border: const Border(
          left: BorderSide(color: AppTheme.primaryContainer, width: 3),
        ),
        boxShadow: AppTheme.crimsonShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'T03',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#1042',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: AppTheme.secondary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 10,
                            color: AppTheme.error,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '07:23 🔴',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryFixed,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'COOKING',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onPrimaryFixedVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Wagyu Burger x1 · Dal Makhani x2',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: AppTheme.surfaceContainer, thickness: 1, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Total',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.secondary,
                ),
              ),
              Text(
                '₹2,410',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildQuickActions(List<_QuickAction> actions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.asMap().entries.map((entry) {
          return _QuickActionButton(action: entry.value)
              .animate(delay: Duration(milliseconds: 100 * entry.key))
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
        }).toList(),
      ),
    );
  }
}

// ── KPI Data Model ────────────────────────────────────────────────────────────
class _KpiData {
  final String label;
  final String value;
  final String? delta;
  final bool deltaPositive;
  final bool showSparkline;
  final bool showBar;
  final double barValue;
  final bool showDots;
  final int activeDots;
  final int totalDots;

  const _KpiData({
    required this.label,
    required this.value,
    this.delta,
    this.deltaPositive = true,
    this.showSparkline = false,
    this.showBar = false,
    this.barValue = 0,
    this.showDots = false,
    this.activeDots = 0,
    this.totalDots = 8,
  });
}

// ── KPI Card ──────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            data.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.secondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              if (data.delta != null)
                Text(
                  data.delta!,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: data.deltaPositive
                        ? const Color(0xFF059669)
                        : AppTheme.error,
                  ),
                ),
              if (data.showSparkline) _buildSparkline(),
              if (data.showBar) _buildBar(),
              if (data.showDots) _buildDots(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSparkline() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 28,
        child: CustomPaint(
          painter: _SparklinePainter(),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _buildBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9999),
        child: LinearProgressIndicator(
          value: data.barValue,
          backgroundColor: AppTheme.surfaceContainer,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          minHeight: 4,
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: List.generate(data.totalDots, (i) {
          final active = i < data.activeDots;
          return Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppTheme.primary : AppTheme.surfaceContainer,
            ),
          );
        }),
      ),
    );
  }
}

// ── Sparkline Painter ─────────────────────────────────────────────────────────
class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final points = [
      Offset(0, size.height * 0.85),
      Offset(size.width * 0.2, size.height * 0.72),
      Offset(size.width * 0.4, size.height * 0.30),
      Offset(size.width * 0.6, size.height * 0.55),
      Offset(size.width * 0.8, size.height * 0.15),
      Offset(size.width, size.height * 0.38),
    ];

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final midX = (points[i].dx + points[i + 1].dx) / 2;
      path.cubicTo(
        midX,
        points[i].dy,
        midX,
        points[i + 1].dy,
        points[i + 1].dx,
        points[i + 1].dy,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Quick Action Data + Button ─────────────────────────────────────────────────
class _QuickAction {
  final IconData icon;
  final String label;
  const _QuickAction({required this.icon, required this.label});
}

class _QuickActionButton extends StatefulWidget {
  final _QuickAction action;
  const _QuickActionButton({required this.action});

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.action.icon,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.action.label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.secondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
