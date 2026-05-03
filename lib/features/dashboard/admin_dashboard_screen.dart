import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    final items = [
      _NavItem(icon: Icons.dashboard_rounded, label: 'Home'),
      _NavItem(icon: Icons.receipt_long_rounded, label: 'Orders'),
      _NavItem(icon: Icons.deck_rounded, label: 'Tables'),
      _NavItem(icon: Icons.restaurant_rounded, label: 'Menu'),
      _NavItem(icon: Icons.more_horiz_rounded, label: 'More'),
    ];

    return Container(
      height: 64.h + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 20.r,
            offset: Offset(0, -4.h),
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
                      size: 22.r,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? AppTheme.primaryContainer
                            : AppTheme.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    // Active dot
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: active ? 4.r : 0,
                      height: active ? 4.r : 0,
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
        toolbarHeight: 64.h,
        title: Text(
          'More',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              ...links.map(
                (link) =>
                    GestureDetector(
                          onTap: () => context.push(link.route),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLowest,
                              borderRadius: AppTheme.radiusMd,
                              border: Border.all(
                                color: AppTheme.surfaceContainerHigh,
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44.r,
                                  height: 44.r,
                                  decoration: BoxDecoration(
                                    color: link.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    link.icon,
                                    color: link.color,
                                    size: 22.r,
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Text(
                                    link.label,
                                    style: GoogleFonts.inter(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppTheme.secondary,
                                  size: 24.r,
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
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/role-select');
                },
                icon: Icon(Icons.logout_rounded, size: 18.r),
                label: Text('Sign Out', style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: AppTheme.error,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                ),
              ),
            ],
          ),
        ),
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

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
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

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => CustomScrollView(
          slivers: [
            // ── Top App Bar ─────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: AppTheme.surfaceContainerLowest,
              elevation: 1,
              toolbarHeight: 64.h,
              shadowColor: AppTheme.surfaceContainerHigh,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    backgroundColor: AppTheme.surfaceContainer,
                    child: Text(
                      (user?.email?.isNotEmpty == true)
                          ? user!.email![0].toUpperCase()
                          : 'A',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryContainer,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_greeting, Admin',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          'The Grand Spice',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: AppTheme.secondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── KPI Grid ─────────────────────────────────────────────────
                  _buildSectionHeader('Overview'),
                  SizedBox(height: 12.h),
                  _buildKpiGrid(kpis, constraints),
                  SizedBox(height: 20.h),

                  // ── Live Orders ───────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Live Orders'),
                      TextButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.arrow_forward_rounded, size: 14.r),
                        label: Text(
                          'See All',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
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
                  SizedBox(height: 12.h),
                  _buildOrderCard(),
                  SizedBox(height: 20.h),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: AppTheme.onSurface,
      ),
    );
  }

  Widget _buildKpiGrid(List<_KpiData> kpis, BoxConstraints constraints) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220.w,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: constraints.maxWidth > 600 ? 2.5 : 1.1,
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
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        border: Border(
          left: BorderSide(color: AppTheme.primaryContainer, width: 3.w),
        ),
        boxShadow: AppTheme.crimsonShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'T03',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#1042',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11.sp,
                              color: AppTheme.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 10.r,
                                color: AppTheme.error,
                              ),
                              SizedBox(width: 2.w),
                              Flexible(
                                child: Text(
                                  '07:23 🔴',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.error,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryFixed,
                  borderRadius: BorderRadius.circular(9999.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'COOKING',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.sp,
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
          SizedBox(height: 12.h),
          Text(
            'Wagyu Burger x1 · Dal Makhani x2',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12.h),
          Divider(color: AppTheme.surfaceContainer, thickness: 1.h, height: 1.h),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Total',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppTheme.secondary,
                ),
              ),
              Text(
                '₹2,410',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14.sp,
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
      padding: EdgeInsets.all(16.r),
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
              fontSize: 11.sp,
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
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (data.delta != null)
                Text(
                  data.delta!,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: data.deltaPositive
                        ? const Color(0xFF059669)
                        : AppTheme.error,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      padding: EdgeInsets.only(top: 8.h),
      child: SizedBox(
        height: 28.h,
        child: CustomPaint(
          painter: _SparklinePainter(),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _buildBar() {
    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9999.r),
        child: LinearProgressIndicator(
          value: data.barValue,
          backgroundColor: AppTheme.surfaceContainer,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          minHeight: 4.h,
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Wrap(
        spacing: 4.w,
        runSpacing: 4.h,
        children: List.generate(data.totalDots, (i) {
          final active = i < data.activeDots;
          return Container(
            width: 6.r,
            height: 6.r,
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
      ..strokeWidth = 1.5.w
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
