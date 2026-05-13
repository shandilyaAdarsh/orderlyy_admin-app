import 'dart:convert';

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
import '../analytics/analytics_screen.dart';

// ── Bottom Nav State ──────────────────────────────────────────────────────────
final _currentNavIndexProvider = StateProvider<int>((ref) => 0);

String _normalizeOrderStatus(dynamic status) {
  final raw = status?.toString().toLowerCase().trim() ?? '';
  if (raw == 'rejected' || raw == 'completed') return 'served';
  if (raw.isEmpty) return 'pending';
  return raw;
}

String _displayOrderStatus(dynamic status) {
  return _normalizeOrderStatus(status).toUpperCase();
}

String _displayTableLabel(Map<String, dynamic> order) {
  final tableNum =
      order['table_num'] ??
      order['table_number'] ??
      order['tableNo'] ??
      order['table'];
  if (tableNum != null) {
    final numStr = tableNum.toString().padLeft(2, '0');
    return 'T$numStr';
  }

  final rawId = order['table_id']?.toString() ?? '';
  if (rawId.isNotEmpty && rawId.length <= 4) return rawId;
  return 'T??';
}

List<Map<String, dynamic>> _extractOrderItems(Map<String, dynamic> order) {
  dynamic raw = order['items'] ?? order['order_items'];
  if (raw is String) {
    try {
      raw = jsonDecode(raw);
    } catch (_) {
      raw = [];
    }
  }
  if (raw is! List) return [];

  return raw.map<Map<String, dynamic>>((item) {
    if (item is Map<String, dynamic>) return item;
    if (item is Map) return Map<String, dynamic>.from(item);
    return {'name': item.toString()};
  }).toList();
}

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
          AnalyticsScreen(),
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
      _NavItem(icon: Icons.receipt_long_rounded, label: 'Order'),
      _NavItem(icon: Icons.deck_rounded, label: 'Tables'),
      _NavItem(icon: Icons.bar_chart_rounded, label: 'Analytics'),
      _NavItem(icon: Icons.grid_view_rounded, label: 'Manage'),
    ];

    return Container(
      height: 80.h + MediaQuery.of(context).padding.bottom,
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
      (
        icon: Icons.restaurant_rounded,
        label: 'Menu Management',
        route: '/admin/menu',
        color: const Color(0xFFC0272D),
      ),
      (
        icon: Icons.group_rounded,
        label: 'Staff Management',
        route: '/admin/staff',
        color: const Color(0xFF2563EB),
      ),
      (
        icon: Icons.person_rounded,
        label: 'Profile',
        route: '/admin/profile',
        color: AppTheme.secondary,
      ),
      (
        icon: Icons.settings_rounded,
        label: 'Settings',
        route: '/admin/settings',
        color: AppTheme.secondary,
      ),
    ];
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Manage',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            ...links.map(
              (link) =>
                  GestureDetector(
                        onTap: () => context.push(link.route),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 10.h),
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                                width: 40.r,
                                height: 40.r,
                                decoration: BoxDecoration(
                                  color: link.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(
                                  link.icon,
                                  color: link.color,
                                  size: 20.r,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  link.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
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
              label: Text(
                'Sign Out',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                foregroundColor: AppTheme.error,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 12.h),
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
  void _showNotifications(
    BuildContext context,
    List<Map<String, dynamic>> urgentOrders,
  ) {
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

  static List<Map<String, dynamic>> _todayOrders(
    List<Map<String, dynamic>> all,
  ) {
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

    Stream<List<Map<String, dynamic>>> ordersStream;
    try {
      ordersStream = Supabase.instance.client
          .from('orders')
          .stream(primaryKey: ['id']);
    } catch (e) {
      debugPrint('Orders realtime stream unavailable: $e');
      ordersStream = Stream.fromFuture(
        Future(() async {
          try {
            final data = await Supabase.instance.client.from('orders').select();
            return List<Map<String, dynamic>>.from(data.cast<Map>());
          } catch (e) {
            debugPrint('Orders one-shot fetch failed: $e');
          }
          return <Map<String, dynamic>>[];
        }),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Text(
                'Sync Error: ${snapshot.error}',
                style: GoogleFonts.inter(color: AppTheme.error),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final allOrders = snapshot.data ?? [];
        final today = _todayOrders(allOrders);

        // ── Compute KPIs ────────────────────────────────────────────────────
        final totalSales = today.fold<double>(
          0,
          (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0),
        );
        final totalOrders = today.length;

        // Proxy for total customers (unique tables for today)
        final totalCustomers = today
            .map((o) => o['table_num'] ?? o['table_number'] ?? o['table_id'])
            .toSet()
            .length;

        const trendSales = '+10.5%';
        const activeStatuses = ['pending', 'cooking', 'ready'];

        // ── Urgent orders for bell badge ────────────────────────────────────
        final urgentOrders = allOrders
            .where(
              (o) =>
                  activeStatuses.contains(_normalizeOrderStatus(o['status'])),
            )
            .toList();
        final hasUrgent = urgentOrders.isNotEmpty;

        // ── Top 2 live orders ───────────────────────────────────────────────
        final liveOrders =
            allOrders
                .where(
                  (o) =>
                      _normalizeOrderStatus(o['status']) != 'served' &&
                      _normalizeOrderStatus(o['status']) != 'cancelled',
                )
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
                          (() {
                            final email = user?.email;
                            return (email != null && email.isNotEmpty)
                                ? email[0].toUpperCase()
                                : 'A';
                          })(),
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
                  actions: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.notifications_none_rounded,
                            color: AppTheme.onSurface,
                            size: 24.r,
                          ),
                          onPressed: () =>
                              _showNotifications(context, urgentOrders),
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
                                border: Border.all(
                                  color: AppTheme.surfaceContainerLowest,
                                  width: 1.5.w,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 8.w),
                  ],
                ),

                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Sales Overview Section ─────────────────────────────
                      Text(
                        "Todays Overview",
                        style: GoogleFonts.inter(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Hero Revenue Card
                      _HeroRevenueCard(
                        value: _fmtCurrency(totalSales),
                        trend: trendSales,
                        loading:
                            snapshot.connectionState ==
                                ConnectionState.waiting &&
                            allOrders.isEmpty,
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                      SizedBox(height: 16.h),

                      // KPI Grid
                      _ModernKpiGrid(
                            orders: totalOrders,
                            customers: totalCustomers,
                            avgOrder: totalOrders > 0
                                ? totalSales / totalOrders
                                : 0,
                            loading:
                                snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                allOrders.isEmpty,
                          )
                          .animate(delay: 150.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1),
                      SizedBox(height: 20.h),
                      SizedBox(height: 24.h),

                      // ── Live Orders Header ──────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Live Orders',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                ref
                                        .read(_currentNavIndexProvider.notifier)
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

                      // ── Live Order Cards ────────────────────────────────────
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          allOrders.isEmpty)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.r),
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryContainer,
                            ),
                          ),
                        )
                      else if (top2.isEmpty)
                        Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLow,
                            borderRadius: AppTheme.radiusMd,
                          ),
                          child: Center(
                            child: Text(
                              'No active orders right now 🎉',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ),
                        )
                      else
                        ...top2.asMap().entries.map((entry) {
                          final o = entry.value;
                          final tableId = _displayTableLabel(o);
                          final rawId = o['id']?.toString() ?? 'ORD';
                          final orderId = rawId.length >= 6
                              ? rawId.substring(0, 6).toUpperCase()
                              : rawId.toUpperCase();
                          final status = _displayOrderStatus(o['status']);
                          final isUrgent =
                              _normalizeOrderStatus(o['status']) == 'pending';
                          final items = _extractOrderItems(o);
                          final itemSummary = items.isEmpty
                              ? 'No item details'
                              : items
                                    .take(2)
                                    .map(
                                      (i) =>
                                          '${i['name'] ?? i['item_name'] ?? 'Item'} x${i['quantity'] ?? i['qty'] ?? 1}',
                                    )
                                    .join(' · ');

                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: _buildOrderCard(
                              table: tableId,
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
        border: Border(
          left: BorderSide(
            color: isUrgent ? AppTheme.error : AppTheme.primaryContainer,
            width: 3.w,
          ),
        ),
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$table · #$orderId',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: (isUrgent ? AppTheme.error : AppTheme.primaryContainer)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: isUrgent
                        ? AppTheme.error
                        : AppTheme.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            items,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: AppTheme.error,
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              Text(
                'Urgent Attention',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${urgentOrders.length}',
                  style: GoogleFonts.inter(
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
                  'No urgent alerts right now ✅',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
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
                  final tableId = _displayTableLabel(o);
                  final status = _displayOrderStatus(o['status']);
                  final amount = o['total_amount']?.toString() ?? '0';
                  return Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.04),
                      borderRadius: AppTheme.radiusSm,
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40.r,
                          height: 40.r,
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              tableId,
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
                                'Table $tableId — $status',
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '₹$amount pending',
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

// ── Hero Revenue Card ────────────────────────────────────────────────────────
class _HeroRevenueCard extends StatelessWidget {
  final String value;
  final String trend;
  final bool loading;

  const _HeroRevenueCard({
    required this.value,
    required this.trend,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC0272D), Color(0xFF7F1D1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC0272D).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
                'TOTAL REVENUE',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 14.r,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      trend,
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
          SizedBox(height: 12.h),
          if (loading)
            Container(
              width: 140.w,
              height: 44.h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 40.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
            ),
          SizedBox(height: 8.h),
          Text(
            'vs. Yesterday',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modern KPI Grid ──────────────────────────────────────────────────────────
class _ModernKpiGrid extends StatelessWidget {
  final int orders;
  final int customers;
  final double avgOrder;
  final bool loading;

  const _ModernKpiGrid({
    required this.orders,
    required this.customers,
    required this.avgOrder,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16.w,
      mainAxisSpacing: 16.h,
      // Square tiles (1.0) provide a balanced height.
      // Adjusted from 0.8 to 1.0 to prevent vertical overflow on smaller screens.
      childAspectRatio: 1.0,
      children: [
        _KpiTile(
          label: 'ORDERS',
          value: '$orders',
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFF8B5CF6),
          loading: loading,
        ),
        _KpiTile(
          label: 'CUSTOMERS',
          value: '$customers',
          icon: Icons.people_rounded,
          color: const Color(0xFF06B6D4),
          loading: loading,
        ),
        _KpiTile(
          label: 'AVG ORDER',
          value: '₹${avgOrder.toStringAsFixed(0)}',
          icon: Icons.shopping_cart_rounded,
          color: const Color(0xFF10B981),
          loading: loading,
        ),
        _KpiTile(
          label: 'PREP TIME',
          value: '18m',
          icon: Icons.timer_rounded,
          color: const Color(0xFFF59E0B),
          loading: loading,
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool loading;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(5.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 14.r),
          ),
          const Spacer(flex: 1),
          if (loading)
            Container(
              width: 40.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(4.r),
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1F2937),
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9CA3AF),
              letterSpacing: 0.5,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

// ——————————————————————————————————————————————————————————————
