import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/mock_auth_provider.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/role_select_screen.dart';
import '../../features/auth/admin_login_screen.dart';
import '../../features/auth/staff_login_screen.dart';
import '../../features/auth/change_password_screen.dart';
import '../../features/auth/blocked_screens.dart';
import '../../features/onboarding/onboarding_wizard_screen.dart';
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
import '../../features/staff/staff_management_screen.dart';
import '../../features/debug/debug_screen.dart';
import '../../features/orders/add_order_screen.dart';
import '../data/dtos/order_dto.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // ── RouterNotifier drives GoRouter.refreshListenable ─────────────────────
  // Every time auth state changes (login/logout/restore), the notifier fires
  // notifyListeners() → GoRouter re-runs redirect → correct screen shown.
  // CRITICAL: We use ref.read here instead of ref.watch. Watching the notifier
  // would cause Riverpod to completely recreate the GoRouter instance on every
  // notifyListeners(), resetting navigation history and causing redirect loops.
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      // ── Read auth state directly from providers (reactive via notifier) ───
      final authState = ref.read(authNotifierProvider);
      final currentUserId = authState.userId;
      final staffSession = ref.read(staffSessionProvider);
      final resolvedCtx = ref.read(appContextProvider);
      final loc = state.matchedLocation;

      debugPrint(
        '[ROUTER] location=$loc authStatus=${authState.status} userId=$currentUserId staff=${staffSession?.role}',
      );

      // ── 1. If auth is loading, MUST NOT redirect ───────────────────────────
      if (authState.status == AuthStatus.loading) {
        debugPrint(
          '[ROUTER] ⏳ Auth status is loading. Staying on $loc (redirectResult=null)',
        );
        return null;
      }

      // Debug route always accessible
      if (loc == '/debug') {
        debugPrint('[ROUTER] 🛠️ Debug route allowed (redirectResult=null)');
        return null;
      }

      // ── 2. Determine Login / Role flags ────────────────────────────────────
      final isAdminLoggedIn =
          authState.status == AuthStatus.authenticated &&
          currentUserId != null &&
          !currentUserId.startsWith('staff-');

      final isStaffLoggedIn =
          staffSession != null ||
          (authState.status == AuthStatus.authenticated &&
              currentUserId != null &&
              currentUserId.startsWith('staff-'));

      // isAnyoneLoggedIn: available if redirect logic needs it later
      // final isAnyoneLoggedIn = isAdminLoggedIn || isStaffLoggedIn;

      // postLoginRoutes (reserved — uncomment with isPostLoginRoute when needed):
      // const postLoginRoutes = {
      //   '/change-password', '/subscription-expired',
      //   '/account-suspended', '/onboarding',
      // };

      const publicRoutes = {
        '/splash',
        '/role-select',
        '/admin/login',
        '/staff/login',
      };

      final isPublicRoute = publicRoutes.contains(loc);
      // isPostLoginRoute: reserved for post-login redirect handling
      // final isPostLoginRoute = postLoginRoutes.contains(loc);

      // ── 3. Unauthenticated redirects ────────────────────────────────────────
      if (authState.status == AuthStatus.unauthenticated) {
        if (!isPublicRoute) {
          debugPrint(
            '[ROUTER] 🔒 Protected route "$loc" accessed without session → redirectResult=/role-select',
          );
          return '/role-select';
        }
        if (loc == '/splash') {
          debugPrint(
            '[ROUTER] ℹ️ Unauthenticated on splash → redirectResult=/role-select',
          );
          return '/role-select';
        }
        debugPrint(
          '[ROUTER] ✅ Public route "$loc" allowed for unauthenticated (redirectResult=null)',
        );
        return null;
      }

      // ── 4. Authenticated redirects ──────────────────────────────────────────
      if (authState.status == AuthStatus.authenticated) {
        // A. Resolve flags from context if admin is logged in
        if (isAdminLoggedIn && resolvedCtx != null) {
          final flags = resolvedCtx.flags;
          if (flags.mustChangePassword && loc != '/change-password') {
            debugPrint(
              '[ROUTER] 🔑 Admin password change required → redirectResult=/change-password',
            );
            return '/change-password';
          }
          if (flags.subscriptionExpired && loc != '/subscription-expired') {
            debugPrint(
              '[ROUTER] 💳 Subscription expired → redirectResult=/subscription-expired',
            );
            return '/subscription-expired';
          }
          if (flags.accountSuspended && loc != '/account-suspended') {
            debugPrint(
              '[ROUTER] 🚫 Account suspended → redirectResult=/account-suspended',
            );
            return '/account-suspended';
          }
          if ((!resolvedCtx.onboarding.isComplete ||
                  flags.onboardingRequired) &&
              loc != '/onboarding') {
            debugPrint(
              '[ROUTER] 📋 Admin onboarding required → redirectResult=/onboarding',
            );
            return '/onboarding';
          }
        }

        // B. If on splash or other public routes, route to dashboard
        if (isPublicRoute) {
          if (isAdminLoggedIn) {
            debugPrint(
              '[ROUTER] ✅ Admin logged in on public route → redirectResult=/admin/dashboard',
            );
            return '/admin/dashboard';
          }
          if (isStaffLoggedIn) {
            final role =
                staffSession?.role ??
                (currentUserId != null
                    ? currentUserId.split('-')[1]
                    : 'waiter');
            debugPrint(
              '[ROUTER] ✅ Staff logged in on public route → redirect role=$role',
            );
            if (role == 'waiter') {
              debugPrint('[ROUTER] redirectResult=/staff/tables');
              return '/staff/tables';
            }
            if (role == 'manager') {
              debugPrint('[ROUTER] redirectResult=/manager/dashboard');
              return '/manager/dashboard';
            }
            debugPrint('[ROUTER] redirectResult=/admin/dashboard');
            return '/admin/dashboard';
          }
        }

        // C. Protect admin / staff routes
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

        const protectedStaffRoutes = {
          '/staff/tables',
          '/staff/orders',
          '/staff/inventory',
          '/staff/attention',
          '/staff/add-order',
          '/manager/dashboard',
        };

        final isProtectedAdmin = protectedAdminRoutes.contains(loc);
        final isProtectedStaff = protectedStaffRoutes.contains(loc);

        if (isProtectedAdmin && !isAdminLoggedIn) {
          debugPrint(
            '[ROUTER] 🔒 Protected admin route accessed by non-admin → redirectResult=/role-select',
          );
          return '/role-select';
        }

        if (isProtectedStaff && !isStaffLoggedIn) {
          debugPrint(
            '[ROUTER] 🔒 Protected staff route accessed by non-staff → redirectResult=/role-select',
          );
          return '/role-select';
        }
      }

      debugPrint(
        '[ROUTER] ✅ No redirect needed for $loc (redirectResult=null)',
      );
      return null;
    },
    routes: [
      // ── Debug ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/debug',
        name: 'debug',
        builder: (context, state) => const DebugScreen(),
      ),

      // ── Splash ────────────────────────────────────────────────────────────
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

      // ── Post-Login Gated Routes ──────────────────────────────────────────
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/subscription-expired',
        name: 'subscription-expired',
        builder: (context, state) => const SubscriptionExpiredScreen(),
      ),
      GoRoute(
        path: '/account-suspended',
        name: 'account-suspended',
        builder: (context, state) => const AccountSuspendedScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingWizardScreen(),
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
        path: '/staff/add-order',
        name: 'staff-add-order',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final tableId = extra?['tableId'] as String?;
          final tableLabel = extra?['tableLabel'] as String?;
          final existingOrder = extra?['existingOrder'] as OrderDto?;
          return AddOrderScreen(
            tableId: tableId ?? '',
            tableLabel: tableLabel ?? '',
            existingOrder: existingOrder,
          );
        },
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
