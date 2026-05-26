import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth/mock_auth_provider.dart';
import '../../core/data/dtos/order_dto.dart';
import '../../core/providers/orders_providers.dart';
import '../../core/theme/app_theme.dart';
import '../orders/admin_orders_screen.dart';
import '../analytics/analytics_screen.dart';

// ── Bottom Nav State ──────────────────────────────────────────────────────────
final currentNavIndexProvider = StateProvider<int>((ref) => 0);

// ── Root Shell ────────────────────────────────────────────────────────────────
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(currentNavIndexProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: navIndex,
        children: const [
          _DashboardHome(),
          AdminOrdersScreen(),
          AnalyticsScreen(),
          _MoreTab(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: navIndex,
        onTap: (i) => ref.read(currentNavIndexProvider.notifier).state = i,
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
      (icon: Icons.dashboard_rounded, label: 'Home'),
      (icon: Icons.receipt_long_rounded, label: 'Orders'),
      (icon: Icons.bar_chart_rounded, label: 'Analytics'),
      (icon: Icons.grid_view_rounded, label: 'Manage'),
    ];

    return Container(
      height: 72.h + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: AppTheme.surfaceContainerHigh, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
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
                child: AnimatedContainer(
                  duration: 200.ms,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: 200.ms,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.primaryContainer.withValues(
                                  alpha: 0.12,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          item.icon,
                          color: active
                              ? AppTheme.primaryContainer
                              : AppTheme.secondary,
                          size: 22.r,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active
                              ? AppTheme.primaryContainer
                              : AppTheme.secondary,
                        ),
                      ),
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

// ── More Tab ──────────────────────────────────────────────────────────────────
class _MoreTab extends ConsumerWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? 'admin@orderlli.com';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'A';

    final tiles = [
      (
        icon: Icons.business_rounded,
        label: 'Organization',
        sub: 'Tenant & Branches',
        route: '/admin/organization',
        color: const Color(0xFF0369A1),
      ),
      (
        icon: Icons.restaurant_menu_rounded,
        label: 'Menu',
        sub: 'Items & categories',
        route: '/admin/menu',
        color: const Color(0xFFC0272D),
      ),
      (
        icon: Icons.table_restaurant_rounded,
        label: 'Tables',
        sub: 'QR & layout config',
        route: '/admin/tables',
        color: const Color(0xFF0F766E),
      ),
      (
        icon: Icons.group_rounded,
        label: 'Staff',
        sub: 'Team management',
        route: '/admin/staff',
        color: const Color(0xFF2563EB),
      ),
      (
        icon: Icons.people_outline_rounded,
        label: 'Sessions',
        sub: 'Active guest sessions',
        route: '/admin/guest-sessions',
        color: const Color(0xFFD97706),
      ),
      (
        icon: Icons.devices_rounded,
        label: 'Devices',
        sub: 'POS & KDS monitors',
        route: '/admin/devices',
        color: const Color(0xFF4B5563),
      ),
      (
        icon: Icons.monetization_on_rounded,
        label: 'Pricing',
        sub: 'Base & overrides',
        route: '/admin/pricing',
        color: const Color(0xFF16A34A),
      ),
      (
        icon: Icons.percent_rounded,
        label: 'Taxes',
        sub: 'Vat & service rules',
        route: '/admin/taxes',
        color: const Color(0xFFF59E0B),
      ),
      (
        icon: Icons.alt_route_rounded,
        label: 'Overrides',
        sub: 'Branch inheritance',
        route: '/admin/overrides',
        color: const Color(0xFF0D9488),
      ),
      (
        icon: Icons.receipt_long_rounded,
        label: 'Audit Logs',
        sub: 'Immutable operations',
        route: '/admin/audit',
        color: const Color(0xFF4F46E5),
      ),
      (
        icon: Icons.sync_problem_rounded,
        label: 'OCC Simulator',
        sub: 'Resolve conflicts',
        route: '/admin/occ-conflict',
        color: const Color(0xFFE11D48),
      ),
      (
        icon: Icons.person_rounded,
        label: 'Profile',
        sub: 'Account settings',
        route: '/admin/profile',
        color: const Color(0xFF7C3AED),
      ),
      (
        icon: Icons.settings_rounded,
        label: 'Settings',
        sub: 'App preferences',
        route: '/admin/settings',
        color: AppTheme.secondary,
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: AppTheme.surfaceContainerLowest,
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
                child: Row(
                  children: [
                    Container(
                      width: 52.r,
                      height: 52.r,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFC0272D), Color(0xFF7F1D1D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.inter(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          Text(
                            email,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: AppTheme.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6.r,
                            height: 6.r,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            'ONLINE',
                            style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 100.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Section label ──────────────────────────────────────────
                  Text(
                    'MANAGEMENT',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.secondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // ── 2×2 tile grid ──────────────────────────────────────────
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 1.55,
                    children: tiles.asMap().entries.map((e) {
                      final t = e.value;
                      return GestureDetector(
                            onTap: () => context.push(t.route),
                            child: Container(
                              padding: EdgeInsets.all(16.r),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: AppTheme.surfaceContainerHigh,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36.r,
                                    height: 36.r,
                                    decoration: BoxDecoration(
                                      color: t.color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: Icon(
                                      t.icon,
                                      color: t.color,
                                      size: 18.r,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    t.label,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    t.sub,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate(delay: Duration(milliseconds: 60 * e.key))
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.08);
                    }).toList(),
                  ),

                  SizedBox(height: 28.h),

                  // ── Sign out ───────────────────────────────────────────────
                  GestureDetector(
                    onTap: () async {
                      final authService = ref.read(authServiceProvider);
                      await authService.signOut();
                      if (context.mounted) context.go('/admin/login');
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: AppTheme.error,
                            size: 18.r,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Sign Out',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
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

  static DateTime get _todayMidnight {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static List<OrderDto> _todayOrders(List<OrderDto> all) =>
      all.where((o) => o.createdAt.toLocal().isAfter(_todayMidnight)).toList();

  static String _fmtCurrency(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
    return '₹${v.toStringAsFixed(0)}';
  }

  void _showNotifications(BuildContext context, List<OrderDto> urgent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NotificationSheet(urgentOrders: urgent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final ordersAsync = ref.watch(ordersStreamProvider);

    return ordersAsync.when(
      error: (err, _) => Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Text(
            'Sync Error: $err',
            style: GoogleFonts.inter(color: AppTheme.error),
          ),
        ),
      ),
      loading: () => const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryContainer),
        ),
      ),
      data: (allOrders) {
        final today = _todayOrders(allOrders);
        final totalSales = today.fold<double>(0, (s, o) => s + o.totalAmount);
        final totalOrders = today.length;
        final totalCustomers = today.map((o) => o.tableId).toSet().length;
        final avgOrder = totalOrders > 0 ? totalSales / totalOrders : 0.0;

        const activeStatuses = [
          OrderStatus.pending,
          OrderStatus.preparing,
          OrderStatus.ready,
        ];
        final urgentOrders = allOrders
            .where((o) => activeStatuses.contains(o.status))
            .toList();

        // Status counts for the strip
        final pendingCount = allOrders
            .where((o) => o.status == OrderStatus.pending)
            .length;
        final preparingCount = allOrders
            .where((o) => o.status == OrderStatus.preparing)
            .length;
        final readyCount = allOrders
            .where((o) => o.status == OrderStatus.ready)
            .length;

        // Live orders feed (non-served, non-cancelled, newest first)
        final liveOrders =
            allOrders
                .where(
                  (o) =>
                      o.status != OrderStatus.served &&
                      o.status != OrderStatus.cancelled,
                )
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final feedOrders = liveOrders.take(3).toList();

        return SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── App Bar ────────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: AppTheme.surfaceContainerLowest,
                elevation: 0,
                toolbarHeight: 64.h,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: AppTheme.surfaceContainerHigh,
                  ),
                ),
                title: Row(
                  children: [
                    Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFC0272D), Color(0xFF7F1D1D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (() {
                            final e = user?.email ?? '';
                            return e.isNotEmpty ? e[0].toUpperCase() : 'A';
                          })(),
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_greeting 👋',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'The Grand Spice',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notification bell
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: AppTheme.onSurface,
                            size: 22.r,
                          ),
                          onPressed: () =>
                              _showNotifications(context, urgentOrders),
                        ),
                        if (urgentOrders.isNotEmpty)
                          Positioned(
                            top: 12.h,
                            right: 12.w,
                            child: Container(
                              width: 8.r,
                              height: 8.r,
                              decoration: BoxDecoration(
                                color: AppTheme.error,
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
              ),

              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 100.h),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Hero Revenue Card ──────────────────────────────────────
                    _HeroRevenueCard(
                      value: _fmtCurrency(totalSales),
                      orders: totalOrders,
                      customers: totalCustomers,
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),
                    SizedBox(height: 16.h),

                    // ── Status Strip ───────────────────────────────────────────
                    _StatusStrip(
                      pending: pendingCount,
                      preparing: preparingCount,
                      ready: readyCount,
                    ).animate(delay: 100.ms).fadeIn(duration: 350.ms),
                    SizedBox(height: 20.h),

                    // ── KPI Row ────────────────────────────────────────────────
                    _KpiRow(
                      avgOrder: avgOrder,
                      totalOrders: totalOrders,
                      totalCustomers: totalCustomers,
                    ).animate(delay: 150.ms).fadeIn(duration: 350.ms),
                    SizedBox(height: 24.h),

                    // ── Quick Actions ──────────────────────────────────────────
                    _QuickActionsRow(
                      onOrders: () =>
                          ref.read(currentNavIndexProvider.notifier).state = 1,
                      onAnalytics: () =>
                          ref.read(currentNavIndexProvider.notifier).state = 2,
                      onMenu: () => context.push('/admin/menu'),
                      onStaff: () => context.push('/admin/staff'),
                    ).animate(delay: 200.ms).fadeIn(duration: 350.ms),
                    SizedBox(height: 24.h),

                    // ── Live Orders Feed ───────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Live Orders',
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            if (liveOrders.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 7.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(
                                  '${liveOrders.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        TextButton(
                          onPressed: () =>
                              ref
                                      .read(currentNavIndexProvider.notifier)
                                      .state =
                                  1,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryContainer,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            'See All →',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    if (feedOrders.isEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 28.h),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 36.r,
                              color: const Color(0xFF10B981),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'All caught up!',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.secondary,
                              ),
                            ),
                            Text(
                              'No active orders right now',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...feedOrders.asMap().entries.map((e) {
                        final o = e.value;
                        return Padding(
                              padding: EdgeInsets.only(bottom: 10.h),
                              child: _LiveOrderCard(order: o),
                            )
                            .animate(delay: Duration(milliseconds: 60 * e.key))
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.06);
                      }),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Hero Revenue Card ─────────────────────────────────────────────────────────
class _HeroRevenueCard extends StatelessWidget {
  final String value;
  final int orders;
  final int customers;
  const _HeroRevenueCard({
    required this.value,
    required this.orders,
    required this.customers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC0272D), Color(0xFF7F1D1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC0272D).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TODAY'S REVENUE",
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.65),
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 13.r,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '+10.5%',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 42.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.5,
                height: 1.0,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'vs. yesterday',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 18.h),
          // Mini stats row
          Row(
            children: [
              _HeroStat(label: 'Orders', value: '$orders'),
              Container(
                width: 1,
                height: 28.h,
                color: Colors.white.withValues(alpha: 0.2),
                margin: EdgeInsets.symmetric(horizontal: 16.w),
              ),
              _HeroStat(label: 'Tables', value: '$customers'),
              Container(
                width: 1,
                height: 28.h,
                color: Colors.white.withValues(alpha: 0.2),
                margin: EdgeInsets.symmetric(horizontal: 16.w),
              ),
              _HeroStat(label: 'Avg Time', value: '18m'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// ── Status Strip ──────────────────────────────────────────────────────────────
class _StatusStrip extends StatelessWidget {
  final int pending;
  final int preparing;
  final int ready;
  const _StatusStrip({
    required this.pending,
    required this.preparing,
    required this.ready,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatusChip(
          label: 'PENDING',
          count: pending,
          color: const Color(0xFFF59E0B),
          icon: Icons.hourglass_top_rounded,
        ),
        SizedBox(width: 8.w),
        _StatusChip(
          label: 'PREPARING',
          count: preparing,
          color: const Color(0xFF3B82F6),
          icon: Icons.local_fire_department_rounded,
        ),
        SizedBox(width: 8.w),
        _StatusChip(
          label: 'READY',
          count: ready,
          color: const Color(0xFF10B981),
          icon: Icons.check_circle_outline_rounded,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16.r),
            SizedBox(width: 6.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1.0,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── KPI Row ───────────────────────────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  final double avgOrder;
  final int totalOrders;
  final int totalCustomers;
  const _KpiRow({
    required this.avgOrder,
    required this.totalOrders,
    required this.totalCustomers,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _KpiCard(
          label: 'AVG ORDER',
          value: avgOrder >= 1000
              ? '₹${(avgOrder / 1000).toStringAsFixed(1)}k'
              : '₹${avgOrder.toStringAsFixed(0)}',
          icon: Icons.shopping_bag_outlined,
          color: const Color(0xFF8B5CF6),
        ),
        SizedBox(width: 10.w),
        _KpiCard(
          label: 'ORDERS',
          value: '$totalOrders',
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFF06B6D4),
        ),
        SizedBox(width: 10.w),
        _KpiCard(
          label: 'TABLES',
          value: '$totalCustomers',
          icon: Icons.table_restaurant_outlined,
          color: const Color(0xFF10B981),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30.r,
              height: 30.r,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: color, size: 15.r),
            ),
            SizedBox(height: 10.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                  height: 1.0,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions Row ─────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onOrders;
  final VoidCallback onAnalytics;
  final VoidCallback onMenu;
  final VoidCallback onStaff;
  const _QuickActionsRow({
    required this.onOrders,
    required this.onAnalytics,
    required this.onMenu,
    required this.onStaff,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: Icons.receipt_long_rounded,
        label: 'Orders',
        color: const Color(0xFFC0272D),
        onTap: onOrders,
      ),
      (
        icon: Icons.bar_chart_rounded,
        label: 'Analytics',
        color: const Color(0xFF2563EB),
        onTap: onAnalytics,
      ),
      (
        icon: Icons.restaurant_menu_rounded,
        label: 'Menu',
        color: const Color(0xFF7C3AED),
        onTap: onMenu,
      ),
      (
        icon: Icons.group_rounded,
        label: 'Staff',
        color: const Color(0xFF059669),
        onTap: onStaff,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: actions.map((a) {
            return Expanded(
              child: GestureDetector(
                onTap: a.onTap,
                child: Container(
                  margin: EdgeInsets.only(right: a == actions.last ? 0 : 8.w),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppTheme.surfaceContainerHigh),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40.r,
                        height: 40.r,
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(a.icon, color: a.color, size: 20.r),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        a.label,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Live Order Card ───────────────────────────────────────────────────────────
class _LiveOrderCard extends StatelessWidget {
  final OrderDto order;
  const _LiveOrderCard({required this.order});

  Color get _statusColor => switch (order.status) {
    OrderStatus.pending => const Color(0xFFF59E0B),
    OrderStatus.preparing => const Color(0xFF3B82F6),
    OrderStatus.ready => const Color(0xFF10B981),
    OrderStatus.confirmed => const Color(0xFF8B5CF6),
    _ => AppTheme.secondary,
  };

  String get _statusLabel => switch (order.status) {
    OrderStatus.pending => 'PENDING',
    OrderStatus.preparing => 'PREPARING',
    OrderStatus.ready => 'READY',
    OrderStatus.confirmed => 'CONFIRMED',
    _ => order.status.name.toUpperCase(),
  };

  String get _timeAgo {
    final diff = DateTime.now().difference(order.createdAt.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = order.status == OrderStatus.pending;
    final itemSummary = order.items.isEmpty
        ? 'No items'
        : order.items
              .take(2)
              .map((i) => '${i.menuItemName} ×${i.quantity}')
              .join('  ·  ');
    final hasMore = order.items.length > 2;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _statusColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left accent + table badge
          Column(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    order.tableLabel.length > 4
                        ? order.tableLabel.substring(0, 4)
                        : order.tableLabel,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: _statusColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#${order.id.length >= 6 ? order.id.substring(0, 6).toUpperCase() : order.id.toUpperCase()}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ),
                    // Status chip
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        _statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: _statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  '$itemSummary${hasMore ? '  +${order.items.length - 2} more' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 11.r,
                      color: AppTheme.secondary,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      _timeAgo,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: isUrgent ? AppTheme.error : AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification Sheet ────────────────────────────────────────────────────────
class _NotificationSheet extends StatelessWidget {
  final List<OrderDto> urgentOrders;
  const _NotificationSheet({required this.urgentOrders});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: AppTheme.error,
                  size: 18.r,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Needs Attention',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${urgentOrders.length}',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (urgentOrders.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Text(
                  'No urgent alerts ✅',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 300.h),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: urgentOrders.length,
                separatorBuilder: (context, idx) => SizedBox(height: 8.h),
                itemBuilder: (context, i) {
                  final o = urgentOrders[i];
                  return Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38.r,
                          height: 38.r,
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              o.tableLabel.length > 3
                                  ? o.tableLabel.substring(0, 3)
                                  : o.tableLabel,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.error,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Table ${o.tableLabel} — ${o.status.name.toUpperCase()}',
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              Text(
                                '₹${o.totalAmount.toStringAsFixed(0)} · ${o.items.length} items',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14.r,
                          color: AppTheme.secondary,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
