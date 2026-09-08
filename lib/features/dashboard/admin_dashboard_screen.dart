import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth/app_auth_provider.dart';
import '../../core/auth/bootstrap_provider.dart';
import '../../core/auth/bootstrap_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../orders/domain/models/order.dart';
import '../orders/domain/models/order_status.dart';
import '../../core/providers/orders_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/app_config.dart';
import '../../core/providers/menu_items_provider.dart';
import 'data/repositories/dashboard_repository.dart';
import '../orders/admin_orders_screen.dart';
import '../analytics/analytics_screen.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/providers/branch_context_service.dart';
import '../orders/providers/live_active_orders_provider.dart';
import '../../core/providers/analytics_provider.dart';

// ── State Providers ──────────────────────────────────────────────────────────
final currentNavIndexProvider = StateProvider<int>((ref) => 0);
final storeOpenProvider = StateProvider<bool>((ref) => true);

// ── Responsive Layout Breakpoint ──────────────────────────────────────────────
bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= 960;

// ── Root Shell ────────────────────────────────────────────────────────────────
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── DASHBOARD SAFETY ASSERTIONS ───────────────────────────────────────────
    final bootstrap = ref.read(bootstrapProvider);
    assert(
      bootstrap.status == BootstrapStatus.tenantReady,
      'Dashboard initialization requires BootstrapStatus.tenantReady. Found: ${bootstrap.status}',
    );
    final appCtx = ref.read(appContextProvider);
    assert(
      appCtx?.user.id == Supabase.instance.client.auth.currentUser?.id,
      'Dashboard user ID must match Supabase authenticated user ID.',
    );

    final navIndex = ref.watch(currentNavIndexProvider);
    final desktop = isDesktop(context);

    final List<Widget> screens = const [
      _DashboardHome(),
      AdminOrdersScreen(),
      AnalyticsScreen(),
      _MoreTab(),
    ];

    if (desktop) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Row(
          children: [
            const _DesktopSidebar(),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppTheme.surfaceContainerHigh,
            ),
            Expanded(
              child: IndexedStack(index: navIndex, children: screens),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(index: navIndex, children: screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: navIndex,
        onTap: (i) => ref.read(currentNavIndexProvider.notifier).state = i,
      ),
    );
  }
}

// ── Desktop Left Sidebar Navigation ───────────────────────────────────────────
class _DesktopSidebar extends ConsumerWidget {
  const _DesktopSidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(currentNavIndexProvider);
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? 'chef.alex@orderlyy.com';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'A';
    final name = email.split('@').first;
    final capitalizedName = name.isNotEmpty
        ? name[0].toUpperCase() + name.substring(1)
        : 'Chef';

    return Container(
      width: 240.w,
      height: double.infinity,
      color: AppTheme.surfaceContainerLowest,
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              children: [
                Icon(Icons.store_rounded, color: AppTheme.primary, size: 28.r),
                SizedBox(width: 10.w),
                Text(
                  'KitchenSync',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),

          // CORE OPERATIONS
          _buildSectionHeader('CORE OPERATIONS'),
          _SidebarItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            active: navIndex == 0,
            onTap: () => ref.read(currentNavIndexProvider.notifier).state = 0,
          ),
          _SidebarItem(
            icon: Icons.receipt_long_rounded,
            label: 'Live Orders',
            active: navIndex == 1,
            onTap: () => ref.read(currentNavIndexProvider.notifier).state = 1,
          ),
          _SidebarItem(
            icon: Icons.bar_chart_rounded,
            label: 'Analytics',
            active: navIndex == 2,
            onTap: () => ref.read(currentNavIndexProvider.notifier).state = 2,
          ),
          SizedBox(height: 16.h),

          // STUDIO & SETTINGS
          _buildSectionHeader('STUDIO CONFIG'),
          _SidebarItem(
            icon: Icons.restaurant_menu_rounded,
            label: 'Menu Manager',
            onTap: () => context.push('/admin/menu'),
          ),
          _SidebarItem(
            icon: Icons.grid_view_rounded,
            label: 'Table & Floor Monitor',
            onTap: () => context.push('/admin/live-floorplan'),
          ),
          _SidebarItem(
            icon: Icons.table_restaurant_rounded,
            label: 'Tables & QR Builder',
            onTap: () => context.push('/admin/tables'),
          ),
          _SidebarItem(
            icon: Icons.group_rounded,
            label: 'Staff & Team',
            onTap: () => context.push('/admin/staff'),
          ),
          _SidebarItem(
            icon: Icons.people_outline_rounded,
            label: 'Guest Sessions',
            onTap: () => context.push('/admin/guest-sessions'),
          ),
          const Spacer(),

          // Profile row at bottom
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    initial,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        capitalizedName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        email,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.sp,
                          color: AppTheme.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.logout_rounded,
                    color: AppTheme.error,
                    size: 18.r,
                  ),
                  onPressed: () async {
                    final authService = ref.read(authServiceProvider);
                    await authService.signOut();
                    if (context.mounted) context.go('/admin/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, bottom: 8.h, top: 8.h),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
          color: AppTheme.secondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: AnimatedContainer(
            duration: 150.ms,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.primaryContainer.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: active ? AppTheme.primary : AppTheme.secondary,
                  size: 20.r,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.sp,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppTheme.primary : AppTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mobile Bottom Navigation Bar ──────────────────────────────────────────────
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
      height: 64.h + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: AppTheme.surfaceContainerHigh, width: 1.w),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, -4),
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
                    AnimatedContainer(
                      duration: 150.ms,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.primaryContainer.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Icon(
                        item.icon,
                        color: active ? AppTheme.primary : AppTheme.secondary,
                        size: 22.r,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      item.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? AppTheme.primary : AppTheme.secondary,
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

// ── Mobile More / Management Tab ──────────────────────────────────────────────
class _MoreTab extends ConsumerWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? 'chef.alex@orderlyy.com';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'A';
    final name = email.split('@').first;
    final capitalizedName = name.isNotEmpty
        ? name[0].toUpperCase() + name.substring(1)
        : 'Chef';

    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            // Top branding/header
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 24.w),
              child: Row(
                children: [
                  Icon(Icons.store_rounded, color: AppTheme.primary, size: 26.r),
                  SizedBox(width: 10.w),
                  Text(
                    'Orderlyy',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            
            // List
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CORE OPERATIONS
                    _buildSectionHeader('CORE OPERATIONS'),
                    _SidebarItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      onTap: () => ref.read(currentNavIndexProvider.notifier).state = 0,
                    ),
                    _SidebarItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'Live Orders',
                      onTap: () => ref.read(currentNavIndexProvider.notifier).state = 1,
                    ),
                    _SidebarItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Analytics',
                      onTap: () => ref.read(currentNavIndexProvider.notifier).state = 2,
                    ),
                    SizedBox(height: 16.h),

                    // STUDIO CONFIG
                    _buildSectionHeader('STUDIO CONFIG'),
                    _SidebarItem(
                      icon: Icons.restaurant_menu_rounded,
                      label: 'Menu Manager',
                      onTap: () => context.push('/admin/menu'),
                    ),
                    _SidebarItem(
                      icon: Icons.table_restaurant_rounded,
                      label: 'Tables & QR',
                      onTap: () => context.push('/admin/tables'),
                    ),
                    _SidebarItem(
                      icon: Icons.grid_view_rounded,
                      label: 'Table & Floor Monitor',
                      onTap: () => context.push('/admin/live-floorplan'),
                    ),
                    _SidebarItem(
                      icon: Icons.group_rounded,
                      label: 'Staff & Team',
                      onTap: () => context.push('/admin/staff'),
                    ),
                    SizedBox(height: 16.h),

                    // FINANCIALS
                    _buildSectionHeader('FINANCIALS'),
                    _SidebarItem(
                      icon: Icons.percent_rounded,
                      label: 'Tax Matrix',
                      onTap: () => context.push('/admin/taxes'),
                    ),
                    if (!AppConfig.isPilotMode)
                      _SidebarItem(
                        icon: Icons.monetization_on_rounded,
                        label: 'Dynamic Pricing',
                        onTap: () => context.push('/admin/pricing'),
                      ),
                    SizedBox(height: 16.h),

                    // SYSTEM
                    _buildSectionHeader('SYSTEM'),
                    _SidebarItem(
                      icon: Icons.business_rounded,
                      label: 'Organization',
                      onTap: () => context.push('/admin/organization'),
                    ),
                    _SidebarItem(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      onTap: () => context.push('/admin/settings'),
                    ),
                    
                    // ADVANCED
                    if (!AppConfig.isPilotMode) ...[
                      SizedBox(height: 16.h),
                      _buildSectionHeader('ADVANCED'),
                      _SidebarItem(
                        icon: Icons.people_outline_rounded,
                        label: 'Live Sessions',
                        onTap: () => context.push('/admin/guest-sessions'),
                      ),
                      _SidebarItem(
                        icon: Icons.devices_rounded,
                        label: 'Device Manager',
                        onTap: () => context.push('/admin/devices'),
                      ),
                      _SidebarItem(
                        icon: Icons.alt_route_rounded,
                        label: 'Inheritance',
                        onTap: () => context.push('/admin/overrides'),
                      ),
                      _SidebarItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'Audit Log Ledger',
                        onTap: () => context.push('/admin/audit'),
                      ),
                      _SidebarItem(
                        icon: Icons.sync_problem_rounded,
                        label: 'OCC Resolution',
                        onTap: () => context.push('/admin/occ-conflict'),
                      ),
                    ],
                    
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
            
            // Profile row
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
              decoration: BoxDecoration(
                color: AppTheme.background,
                border: Border(top: BorderSide(color: AppTheme.surfaceContainerHigh, width: 1.w)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      initial,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          capitalizedName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          email,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            color: AppTheme.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.logout_rounded, color: AppTheme.error, size: 22.r),
                    onPressed: () async {
                      final authService = ref.read(authServiceProvider);
                      await authService.signOut();
                      if (context.mounted) context.go('/admin/login');
                    },
                    tooltip: 'Logout',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 12.w, bottom: 8.h, top: 12.h),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
          color: AppTheme.secondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ── Tenant Home Command Center (Primary Tab) ──────────────────────────────────
class _DashboardHome extends ConsumerStatefulWidget {
  const _DashboardHome();

  @override
  ConsumerState<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends ConsumerState<_DashboardHome> {


  static DateTime get _todayMidnight {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }



  static String _fmtCurrency(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
    return '₹${v.toStringAsFixed(0)}';
  }

  void _showNotifications(BuildContext context, List<Order> urgent) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NotificationSheet(urgentOrders: urgent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeBranch = ref.watch(currentBranchProvider).value;
    final liveOrdersAsync = ref.watch(liveActiveOrdersProvider);
    final summary = ref.watch(dailySummaryProvider({
      'date': _todayMidnight,
      'branchId': activeBranch?.id,
    }));

    // Trigger fetch if not loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (activeBranch != null) {
        ref.read(analyticsProvider.notifier).fetchDailySummary(
          date: _todayMidnight,
          branchId: activeBranch.id,
        );
      }
    });

    if (liveOrdersAsync.hasError) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Text(
            'Sync Error: ${liveOrdersAsync.error}',
            style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
          ),
        ),
      );
    }

    if (liveOrdersAsync.isLoading && !liveOrdersAsync.hasValue) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryContainer),
        ),
      );
    }

    final allLiveOrders = liveOrdersAsync.value ?? [];
    
    final todaysOrdersCount = summary?.totalOrderCount ?? 0;
    final totalSales = (summary?.totalRevenueAmount ?? 0) / 100.0;

    // final tablesState = ref.watch(tablesProvider);
    // final activeTablesCount = tablesState.tablesById.length;

    final menuItemsState = ref.watch(menuItemsProvider);
    final menuItemsCount = menuItemsState.byId.length;
    final isMenuEmpty = menuItemsCount == 0;

    final appCtx = ref.read(appContextProvider);
    final dismissedQrBanner = appCtx?.tenant.dismissedQrBanner ?? false;

    const activeStatuses = [
      OrderStatus.pending,
      OrderStatus.preparing,
      OrderStatus.ready,
    ];
    final unresolvedOrders = allLiveOrders
        .where((o) => activeStatuses.contains(o.status))
        .toList();

    // Feed orders (live processing, max 3)
    final liveOrders =
        allLiveOrders
            .where(
              (o) =>
                  o.status != OrderStatus.served &&
                  o.status != OrderStatus.cancelled,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final feedOrders = liveOrders.take(3).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: isDesktop(context)
          ? null
          : AppBar(
              backgroundColor: AppTheme.surfaceContainerLowest,
              elevation: 0,
              toolbarHeight: 56.h,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Icon(
                    Icons.store_rounded,
                    color: AppTheme.primary,
                    size: 24.r,
                  ),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      'HOME',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isMenuEmpty ? AppTheme.error.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: isMenuEmpty ? AppTheme.error : Colors.green, width: 1),
                    ),
                    child: Text(
                      isMenuEmpty ? '⚠ Setup Required' : '✓ Ready for Orders',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: isMenuEmpty ? AppTheme.error : Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const BranchSwitcher(),
                  const Spacer(),
                  // Bell icon
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
                            _showNotifications(context, unresolvedOrders),
                      ),
                      if (unresolvedOrders.isNotEmpty)
                        Positioned(
                          top: 10.h,
                          right: 10.w,
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
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(1.h),
                child: Divider(
                  height: 1.h,
                  thickness: 1.h,
                  color: AppTheme.surfaceContainerHigh,
                ),
              ),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Riverpod stream triggers auto update
          },
          color: AppTheme.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop(context) ? 32.w : 16.w,
                  vertical: 24.h,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Store Header + Greeting ───────────────────────────
                    // ── Onboarding Banners ────────────────────────────────────
                    if (!dismissedQrBanner)
                      _buildFirstDashboardBanner(context, ref),
                    if (isMenuEmpty)
                      _buildSetupChecklist(context, ref),

                    // ── Primary App Actions ───────────────────────────
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x08000000),
                                blurRadius: 15,
                                offset: Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          padding: EdgeInsets.all(8.r),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ref.invalidate(ordersProvider);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Refreshing Orderlyy...'),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: AppTheme.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: AppTheme.primary.withValues(alpha: 0.6),
                                    padding: EdgeInsets.symmetric(vertical: 18.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14.r),
                                    ),
                                  ),
                                  icon: Icon(Icons.restaurant_rounded, size: 24.sp),
                                  label: Text(
                                    'Orderlyy',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16.sp,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: TextButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('NoMen - Coming soon'),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF4B6BF5),
                                    backgroundColor: const Color(0xFF4B6BF5).withValues(alpha: 0.05),
                                    padding: EdgeInsets.symmetric(vertical: 18.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14.r),
                                    ),
                                  ),
                                  icon: Icon(Icons.delivery_dining_rounded, size: 24.sp),
                                  label: Text(
                                    'NoMen',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // ── Real-Time Pulse Cards Grid ────────────────────────
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cols = isDesktop(context) ? 4 : 2;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: cols,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: isDesktop(context) ? 1.6 : 1.3,
                          children: [
                            _PulseCard(
                              title: 'Orders Today',
                              value: '$todaysOrdersCount',
                              subtitle: 'Since midnight',
                              icon: Icons.receipt_long_rounded,
                              color: AppTheme.primary,
                            ),
                            _PulseCard(
                              title: 'Total Sales',
                              value: _fmtCurrency(totalSales),
                              subtitle: 'Order value today',
                              icon: Icons.monetization_on_rounded,
                              color: AppTheme.primary,
                            ),
                            _PulseCard(
                              title: 'Active Orders',
                              value: '${liveOrders.length}',
                              subtitle: 'Currently processing',
                              icon: Icons.local_fire_department_rounded,
                              color: Colors.teal,
                              isBadge: true,
                            ),
                            _PulseCard(
                              title: 'Pending Orders',
                              value: '${unresolvedOrders.length}',
                              subtitle: unresolvedOrders.isNotEmpty ? 'Requires attention' : 'All clear',
                              icon: Icons.warning_amber_rounded,
                              color: unresolvedOrders.isNotEmpty ? AppTheme.error : Colors.grey,
                              isError: unresolvedOrders.isNotEmpty,
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 24.h),

                    // ── Main Split Section (Alerts + Sparkline) ───────────
                    if (isDesktop(context))
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildUrgentActionCenter(context),
                          ),
                          SizedBox(width: 24.w),
                          Expanded(flex: 3, child: _buildRevenuePulseChart()),
                        ],
                      )
                    else ...[
                      _buildUrgentActionCenter(context),
                      SizedBox(height: 24.h),
                      _buildRevenuePulseChart(),
                    ],
                    SizedBox(height: 24.h),

                    // ── Quick-Access Launchpad ────────────────────────────
                    _buildQuickActionsLaunchpad(context, ref),
                    SizedBox(height: 28.h),

                    // ── Live Order List Feed ──────────────────────────────
                    _buildLiveOrdersList(context, ref, feedOrders, liveOrders),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Urgent Action Center Builder ────────────────────────────────────────────
  Widget _buildUrgentActionCenter(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1.w),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.surfaceContainerHigh,
                  width: 1.w,
                ),
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Urgent Action Center',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '0 Items',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Alert Items List
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              children: [
                // Empty State for New Account / No Issues
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.secondary.withValues(alpha: 0.5),
                          size: 48.sp,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No urgent actions required',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.secondary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Revenue Pulse Chart Builder ─────────────────────────────────────────────
  Widget _buildRevenuePulseChart() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1.w),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Sales Trend',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    'Today vs Yesterday (Hourly Performance)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.sp,
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppTheme.secondary,
                  size: 20.r,
                ),
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Custom Chart Canvas
          Container(
            height: 200.h,
            width: double.infinity,
            padding: EdgeInsets.only(left: 32.w, right: 16.w, bottom: 20.h),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppTheme.surfaceContainerHigh,
                width: 1.w,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    color: AppTheme.secondary.withValues(alpha: 0.3),
                    size: 48.sp,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'No data available yet',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.secondary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Charts will appear once orders are processed.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.secondary.withValues(alpha: 0.7),
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions Launchpad Builder ─────────────────────────────────────────
  Widget _buildQuickActionsLaunchpad(BuildContext context, WidgetRef ref) {
    final actions = [
      (
        icon: Icons.restaurant_menu_rounded,
        label: 'Edit Menu',
        onTap: () => context.push('/admin/menu'),
      ),
      (
        icon: Icons.local_offer_outlined,
        label: 'Add Discount',
        onTap: () => context.push('/admin/pricing'),
      ),
      (
        icon: Icons.table_restaurant_rounded,
        label: 'Live Floor',
        onTap: () => context.push('/admin/live-floorplan'),
      ),
      (
        icon: Icons.qr_code_rounded,
        label: 'Export QR',
        onTap: () => context.push('/admin/tables'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: actions.map((a) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: a == actions.last ? 0 : 10.w),
                child: InkWell(
                  onTap: a.onTap,
                  borderRadius: BorderRadius.circular(16.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppTheme.surfaceContainerHigh,
                        width: 1.w,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x02000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 20.r,
                          backgroundColor: AppTheme.background,
                          child: Icon(
                            a.icon,
                            color: AppTheme.primary,
                            size: 20.r,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          a.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Live Orders List Builder ────────────────────────────────────────────────
  Widget _buildLiveOrdersList(
    BuildContext context,
    WidgetRef ref,
    List<Order> feedOrders,
    List<Order> liveOrders,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Live Orders Feed',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
                SizedBox(width: 8.w),
                if (liveOrders.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '${liveOrders.length}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            TextButton(
              onPressed: () {
                ref.read(currentNavIndexProvider.notifier).state = 1;
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'See All Feed →',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        if (feedOrders.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 36.h),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 40.r,
                  color: Colors.teal,
                ),
                SizedBox(height: 10.h),
                Text(
                  'All caught up!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                Text(
                  'No active operational orders right now.',
                  style: GoogleFonts.plusJakartaSans(
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
                .slideY(begin: 0.05);
          }),
      ],
    );
  }

  Widget _buildFirstDashboardBanner(BuildContext context, WidgetRef ref) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.celebration_rounded, color: AppTheme.primary, size: 28.r),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to your Orderlyy Dashboard!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Your restaurant floor plan is initialized. Before you can start accepting orders, you need to add items to your menu.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    color: AppTheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: AppTheme.onPrimary),
            onPressed: () async {
              try {
                await ref.read(dashboardRepositoryProvider).dismissQrBanner();
                final userId = ref.read(currentUserProvider)?.id;
                if (userId != null) {
                  await ref.read(bootstrapProvider.notifier).retry(userId);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSetupChecklist(BuildContext context, WidgetRef ref) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3), width: 1.w),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: AppTheme.error, size: 24.r),
              SizedBox(width: 12.w),
              Text(
                'Action Required: Finish Setup',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Your restaurant cannot process orders until you have at least one active menu item. Please head over to the Menu section to add your first item.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.sp,
              color: AppTheme.secondary,
            ),
          ),
          SizedBox(height: 20.h),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(currentNavIndexProvider.notifier).state = 1;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            icon: const Icon(Icons.restaurant_menu_rounded),
            label: Text(
              'Go to Menu Setup',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pulse Card ────────────────────────────────────────────────────────────────
class _PulseCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isError;
  final bool isBadge;

  const _PulseCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isError = false,
    this.isBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isError) {
      return Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppTheme.errorContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppTheme.error.withValues(alpha: 0.2),
            width: 1.w,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x02000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.error, size: 16.r),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.error,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.error,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: AppTheme.error.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1.w),
        boxShadow: const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: CircleAvatar(
              radius: 16.r,
              backgroundColor: AppTheme.background,
              child: Icon(icon, color: color, size: 16.r),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.secondary,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 4.h),
              if (isBadge)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.sp,
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.sp,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Alert Item Widget ────────────────────────────────────────────────────────




// ── Live Order Card Widget ────────────────────────────────────────────────────
class _LiveOrderCard extends StatelessWidget {
  final Order order;
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
            color: _statusColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                order.tableLabel.length > 4
                    ? order.tableLabel.substring(0, 4)
                    : order.tableLabel,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: _statusColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(width: 12.w),
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
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        _statusLabel,
                        style: GoogleFonts.plusJakartaSans(
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 11.r,
                      color: AppTheme.secondary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _timeAgo,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.sp,
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${(order.totalAmount.amountInCents / 100).toStringAsFixed(0)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
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
  final List<Order> urgentOrders;
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
              CircleAvatar(
                radius: 18.r,
                backgroundColor: AppTheme.error.withValues(alpha: 0.1),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: AppTheme.error,
                  size: 18.r,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Needs Attention',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w500,
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
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              Text(
                                '₹${(o.totalAmount.amountInCents / 100).toStringAsFixed(0)} · ${o.items.length} items',
                                style: GoogleFonts.plusJakartaSans(
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

// ── Custom Sparkline Area Painter (Today vs Yesterday) ────────────────────────


