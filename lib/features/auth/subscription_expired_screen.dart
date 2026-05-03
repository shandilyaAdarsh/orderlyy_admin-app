import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/app_context_provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class SubscriptionExpiredScreen extends ConsumerWidget {
  const SubscriptionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BlockedScreen(
      icon: Icons.credit_card_off_rounded,
      title: 'Subscription Expired',
      message:
          'Your restaurant\'s subscription has expired. Please contact your plan administrator to renew and regain access.',
      onLogout: () => _logout(ref, context),
    );
  }

  Future<void> _logout(WidgetRef ref, BuildContext context) async {
    ref.read(appContextProvider.notifier).clearContext();
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) context.go('/role-select');
  }
}

class AccountSuspendedScreen extends ConsumerWidget {
  const AccountSuspendedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BlockedScreen(
      icon: Icons.block_rounded,
      title: 'Account Suspended',
      message:
          'Your account has been suspended. Please contact Orderlli support to resolve this issue.',
      onLogout: () => _logout(ref, context),
    );
  }

  Future<void> _logout(WidgetRef ref, BuildContext context) async {
    ref.read(appContextProvider.notifier).clearContext();
    ref.read(staffSessionProvider.notifier).clear();
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) context.go('/role-select');
  }
}

// ── Shared blocked screen layout ──────────────────────────────────────────────
class _BlockedScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onLogout;

  const _BlockedScreen({
    required this.icon,
    required this.title,
    required this.message,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon,
                      size: 44, color: const Color(0xFFEF4444)),
                ),
                const SizedBox(height: 28),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.secondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text('Sign Out',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.onSurface,
                      side: const BorderSide(
                          color: AppTheme.surfaceContainerHigh, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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
