import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_provider.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/role_select_screen.dart';
import '../../features/auth/admin_login_screen.dart';
import '../../features/auth/staff_login_screen.dart';
import '../../features/dashboard/admin_dashboard_screen.dart';
import '../../features/staff/staff_tables_screen.dart';
import '../../features/staff/manager_dashboard_screen.dart';
import '../../features/staff/needs_attention_screen.dart';
import '../../features/profile/admin_profile_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/orders/admin_orders_screen.dart';
import '../../features/orders/waiter_orders_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/menu/menu_management_screen.dart';
import '../../features/staff_mgmt/staff_management_screen.dart';
import '../../features/debug/debug_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;

      // Read staff session from Riverpod container
      final container = ProviderScope.containerOf(context);
      final staffSession = container.read(staffSessionProvider);

      final isAdminLoggedIn = user != null;
      final isStaffLoggedIn = staffSession != null;
      final isAnyoneLoggedIn = isAdminLoggedIn || isStaffLoggedIn;

      final loc = state.matchedLocation;

      // Debug route always accessible
      if (loc == '/debug') return null;

      const publicRoutes = {'/splash', '/role-select', '/admin/login', '/staff/login'};
      final isPublicRoute = publicRoutes.contains(loc);

      // Logged-in admin on auth screen → admin dashboard
      if (isPublicRoute && isAdminLoggedIn) {
        return '/admin/dashboard';
      }

      // Logged-in staff on auth screen → correct staff screen
      if (isPublicRoute && isStaffLoggedIn) {
        final role = staffSession.role;
        if (role == 'waiter') return '/staff/tables';
        if (role == 'manager') return '/manager/dashboard';
        return '/admin/dashboard';
      }

      // On protected admin routes without any session → role select
      const protectedAdminRoutes = {
        '/admin/dashboard',
        '/admin/orders',
        '/admin/tables',
        '/admin/menu',
        '/admin/analytics',
        '/admin/inventory',
        '/admin/staff',
        '/admin/profile',
        '/admin/settings',
      };
      final isProtectedAdmin = protectedAdminRoutes.contains(loc);
      if (isProtectedAdmin && !isAnyoneLoggedIn) {
        return '/role-select';
      }

      return null;
    },
    routes: [
      // ── Debug ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/debug',
        name: 'debug',
        builder: (context, state) => const DebugScreen(),
      ),

      // ── Onboarding ──────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/role-select',
        name: 'role-select',
        builder: (context, state) => const RoleSelectScreen(),
      ),

      // ── Admin Auth ───────────────────────────────────────────────────────
      GoRoute(
        path: '/admin/login',
        name: 'admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),

      // ── Admin App ───────────────────────────────────────────────────────
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        name: 'admin-orders',
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        name: 'admin-analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/admin/settings',
        name: 'admin-settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/admin/profile',
        name: 'admin-profile',
        builder: (context, state) => const AdminProfileScreen(),
      ),
      GoRoute(
        path: '/admin/inventory',
        name: 'admin-inventory',
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: '/admin/tables',
        name: 'admin-tables',
        builder: (context, state) => const StaffTablesScreen(),
      ),
      GoRoute(
        path: '/admin/menu',
        name: 'admin-menu',
        builder: (context, state) => const MenuManagementScreen(),
      ),
      GoRoute(
        path: '/admin/staff',
        name: 'admin-staff',
        builder: (context, state) => const StaffManagementScreen(),
      ),

      // ── Staff Auth ────────────────────────────────────────────────────────
      GoRoute(
        path: '/staff/login',
        name: 'staff-login',
        builder: (context, state) => const StaffLoginScreen(),
      ),

      // ── Staff App ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/staff/tables',
        name: 'staff-tables',
        builder: (context, state) => const StaffTablesScreen(),
      ),
      GoRoute(
        path: '/staff/orders',
        name: 'staff-orders',
        builder: (context, state) => const WaiterOrdersScreen(),
      ),
      GoRoute(
        path: '/staff/inventory',
        name: 'staff-inventory',
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: '/staff/attention',
        name: 'staff-attention',
        builder: (context, state) => const NeedsAttentionScreen(),
      ),

      // ── Manager ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/manager/dashboard',
        name: 'manager-dashboard',
        builder: (context, state) => const ManagerDashboardScreen(),
      ),
    ],
  );
});
