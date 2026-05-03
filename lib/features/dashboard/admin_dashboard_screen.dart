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
                      color: active ? AppTheme.primaryContainer : AppTheme.secondary,
                      size: 22.r,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: active ? AppTheme.primaryContainer : AppTheme.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
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

// ── More Tab ──────────────────────────────────────────────────────────────────
class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    final links = [
      (icon: Icons.bar_chart_rounded, label: 'Analytics', route: '/admin/analytics', color: const Color(0xFF7C3AED)),
      (icon: Icons.group_rounded, label: 'Staff', route: '/admin/staff', color: const Color(0xFF2563EB)),
      (icon: Icons.inventory_2_rounded, label: 'Inventory', route: '/admin/inventory', color: const Color(0xFF059669)),
      (icon: Icons.person_rounded, label: 'Profile', route: '/admin/profile', color: const Color(0xFFC0272D)),
      (icon: Icons.settings_rounded, label: 'Settings', route: '/admin/settings', color: const Color(0xFF64748B)),
    ];
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 64.h,
        title: Text('More', style: GoogleFonts.inter(fontSize: 20.sp, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            ...links.map(
              (link) => GestureDetector(
                    onTap: () => context.push(link.route),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: AppTheme.radiusMd,
                        border: Border.all(color: AppTheme.surfaceContainerHigh, width: 1.w),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44.r, height: 44.r,
                            decoration: BoxDecoration(color: link.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10.r)),
                            child: Icon(link.icon, color: link.color, size: 22.r),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(child: Text(link.label, style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600, color: AppTheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Icon(Icons.chevron_right_rounded, color: AppTheme.secondary, size: 24.r),
                        ],
                      ),
                    ),
                  )
                  .animate(delay: Duration(milliseconds: 50 * links.indexOf(link)))
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

  // ── Notification Bell Bottom Sheet ─────────────────────────────────────────
  void _showNotifications(BuildContext context, List<Map<String, dynamic>> urgentOrders) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NotificationSheet(urgentOrders: urgentOrders),
    );
  }

  // ── KPI helpers ───────────────────────────────────────────────────────────
  static DateTime get _todayMidnight {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static List<Map<String, dynamic>> _todayOrders(List<Map<String, dynamic>> all) {
    return all.where((o) {
      final raw = o['created_at'];
      if (raw == null) return false;
      try {
        final dt = DateTime.parse(raw.toString()).toLocal();
        return dt.isAfter(_todayMidnight);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  static String _fmtCurrency(double v) {
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}k';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('orders').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        final allOrders = snapshot.data ?? [];
        final today = _todayOrders(allOrders);

        // ── Compute KPIs ────────────────────────────────────────────────────
        final totalSales = today.fold<double>(0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0));
        final totalOrders = today.length;
        final avgOrderVal = totalOrders > 0 ? totalSales / totalOrders : 0.0;

        const activeStatuses = ['pending', 'cooking', 'ready'];
        final occupiedTableIds = allOrders
            .where((o) => activeStatuses.contains((o['status'] ?? '').toString().toLowerCase()))
            .map((o) => o['table_id']?.toString())
            .whereType<String>()
            .toSet();
        const totalActiveQr = 15; // from hardcoded floor map
        final occupiedVsQr = '${occupiedTableIds.length} / $totalActiveQr';

        final kpis = [
          _KpiData(label: 'Total Sales', value: _fmtCurrency(totalSales)),
          _KpiData(label: 'Total Orders', value: '$totalOrders'),
          _KpiData(label: 'Avg Order Val', value: _fmtCurrency(avgOrderVal)),
          _KpiData(label: 'Occupied vs Active QR', value: occupiedVsQr),
        ];

        // ── Urgent orders for bell badge ────────────────────────────────────
        final urgentOrders = allOrders
            .where((o) => activeStatuses.contains((o['status'] ?? '').toString().toLowerCase()))
            .toList();
        final hasUrgent = urgentOrders.isNotEmpty;

        // ── Top 2 live orders ───────────────────────────────────────────────
        final liveOrders = allOrders
            .where((o) => (o['status'] ?? '').toString().toLowerCase() != 'served' &&
                (o['status'] ?? '').toString().toLowerCase() != 'cancelled')
            .toList()
          ..sort((a, b) {
            final ta = a['created_at']?.toString() ?? '';
            final tb = b['created_at']?.toString() ?? '';
            return tb.compareTo(ta);
          });
        final top2 = liveOrders.take(2).toList();

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => CustomScrollView(
              slivers: [
                // ── Top App Bar ───────────────────────────────────────────────
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
                          (user?.email?.isNotEmpty == true) ? user!.email![0].toUpperCase() : 'A',
                          style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppTheme.primaryContainer),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$_greeting, Admin',
                                style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                                overflow: TextOverflow.ellipsis, maxLines: 1),
                            Text('The Grand Spice',
                                style: GoogleFonts.inter(fontSize: 11.sp, color: AppTheme.secondary),
                                overflow: TextOverflow.ellipsis, maxLines: 1),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_none_rounded, color: AppTheme.onSurface, size: 24.r),
                          onPressed: () => _showNotifications(context, urgentOrders),
                        ),
                        if (hasUrgent)
                          Positioned(
                            top: 14.h,
                            right: 14.w,
                            child: Container(
                              width: 8.r,
                              height: 8.r,
                              decoration: BoxDecoration(
                                color: AppTheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.surfaceContainerLowest, width: 1.5.w),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 8.w),
                  ],
                ),

                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Today's Overview Header ─────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's Overview",
                            style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                          ),
                          TextButton(
                            onPressed: () => context.push('/admin/analytics'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryContainer,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                            ),
                            child: Text('More →',
                                style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppTheme.primaryContainer)),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // ── KPI Grid ────────────────────────────────────────────
                      _buildKpiGrid(kpis, constraints, snapshot.connectionState == ConnectionState.waiting && allOrders.isEmpty),
                      SizedBox(height: 24.h),

                      // ── Live Orders Header ──────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Live Orders',
                              style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
                          TextButton(
                            onPressed: () => ref.read(_currentNavIndexProvider.notifier).state = 1,
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryContainer,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                            ),
                            child: Text('See All →',
                                style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppTheme.primaryContainer)),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // ── Live Order Cards ────────────────────────────────────
                      if (snapshot.connectionState == ConnectionState.waiting && allOrders.isEmpty)
                        Center(child: Padding(padding: EdgeInsets.all(20.r), child: CircularProgressIndicator(color: AppTheme.primaryContainer)))
                      else if (top2.isEmpty)
                        Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(color: AppTheme.surfaceContainerLow, borderRadius: AppTheme.radiusMd),
                          child: Center(child: Text('No active orders right now 🎉',
                              style: GoogleFonts.inter(fontSize: 13.sp, color: AppTheme.secondary))),
                        )
                      else
                        ...top2.asMap().entries.map((entry) {
                          final o = entry.value;
                          final tableId = o['table_id']?.toString() ?? 'T-?';
                          final orderId = (o['id']?.toString() ?? 'ORD').substring(0, 6).toUpperCase();
                          final status = (o['status'] ?? 'PENDING').toString().toUpperCase();
                          final isUrgent = (o['status'] ?? '').toString().toLowerCase() == 'pending';
                          List<dynamic> items = o['items'] is List ? o['items'] : [];
                          final itemSummary = items.isEmpty
                              ? 'No item details'
                              : items.take(2).map((i) => i is Map ? '${i['name'] ?? 'Item'} x${i['quantity'] ?? 1}' : i.toString()).join(' · ');

                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: _buildOrderCard(
                              table: 'T$tableId',
                              orderId: orderId,
                              status: status,
                              items: itemSummary,
                              isUrgent: isUrgent,
                            ),
                          );
                        }),
                      SizedBox(height: 20.h),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiGrid(List<_KpiData> kpis, BoxConstraints constraints, bool loading) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220.w,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: constraints.maxWidth > 600 ? 2.5 : 1.45,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, i) {
        return _KpiCard(data: kpis[i], loading: loading)
            .animate(delay: Duration(milliseconds: 100 * i))
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.15, curve: Curves.easeOut);
      },
    );
  }

  Widget _buildOrderCard({
    required String table,
    required String orderId,
    required String status,
    required String items,
    bool isUrgent = false,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        border: Border(left: BorderSide(color: isUrgent ? AppTheme.error : AppTheme.primaryContainer, width: 3.w)),
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$table · #$orderId',
                  style: GoogleFonts.jetBrainsMono(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppTheme.onSurface)),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: (isUrgent ? AppTheme.error : AppTheme.primaryContainer).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(status,
                    style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w800,
                        color: isUrgent ? AppTheme.error : AppTheme.primaryContainer)),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(items,
              style: GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.onSurface.withValues(alpha: 0.7)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Notification Bottom Sheet ─────────────────────────────────────────────────
class _NotificationSheet extends StatelessWidget {
  final List<Map<String, dynamic>> urgentOrders;
  const _NotificationSheet({required this.urgentOrders});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w, height: 4.h,
              decoration: BoxDecoration(color: AppTheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(2.r)),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.notifications_active_rounded, color: AppTheme.error, size: 20.r),
              SizedBox(width: 8.w),
              Text('Urgent Attention',
                  style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20.r)),
                child: Text('${urgentOrders.length}',
                    style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w800, color: AppTheme.error)),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (urgentOrders.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(child: Text('No urgent alerts right now ✅',
                  style: GoogleFonts.inter(fontSize: 14.sp, color: AppTheme.secondary))),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 320.h),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: urgentOrders.length,
                separatorBuilder: (_, _) => SizedBox(height: 10.h),
                itemBuilder: (context, i) {
                  final o = urgentOrders[i];
                  final tableId = o['table_id']?.toString() ?? '?';
                  final status = (o['status'] ?? 'PENDING').toString().toUpperCase();
                  final amount = o['total_amount']?.toString() ?? '0';
                  return Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.04),
                      borderRadius: AppTheme.radiusSm,
                      border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40.r, height: 40.r,
                          decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Center(child: Text('T$tableId',
                              style: GoogleFonts.jetBrainsMono(fontSize: 10.sp, fontWeight: FontWeight.w800, color: AppTheme.error))),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Table $tableId — $status',
                                  style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('₹$amount pending',
                                  style: GoogleFonts.inter(fontSize: 11.sp, color: AppTheme.secondary)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14.r, color: AppTheme.secondary),
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

// ── KPI Data Model ────────────────────────────────────────────────────────────
class _KpiData {
  final String label;
  final String value;
  const _KpiData({required this.label, required this.value});
}

// ── KPI Card ──────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final _KpiData data;
  final bool loading;
  const _KpiCard({required this.data, this.loading = false});

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
          Text(data.label,
              style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w500, color: AppTheme.secondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (loading)
            Container(
              width: 60.w, height: 22.h,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(4.r),
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(data.value,
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 22.sp, fontWeight: FontWeight.w700, color: AppTheme.onSurface, letterSpacing: -0.5)),
            ),
        ],
      ),
    );
  }
}
