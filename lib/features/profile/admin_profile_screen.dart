import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'vikram@thegrandspice.com';
    final initials = email.isNotEmpty ? email[0].toUpperCase() : 'V';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.secondary),
          onPressed: () => context.pop(),
        ),
        title: Text('TableOS',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.secondary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
        children: [
          // Hero
          _HeroCard(initials: initials).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),
          // Plan banner
          _PlanBanner().animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          // Restaurant section
          _Section(
            title: 'RESTAURANT',
            rows: [
              _InfoRow(icon: Icons.storefront_rounded, label: 'Name', value: 'The Grand Spice'),
              _InfoRow(icon: Icons.location_on_rounded, label: 'Location', value: 'South Extension II, New Delhi'),
              _InfoRow(icon: Icons.schedule_rounded, label: 'Operating Hours', value: '11:00 AM – 11:30 PM'),
              _InfoRow(icon: Icons.grid_view_rounded, label: 'Tables', value: '42 Configured', mono: true),
            ],
          ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          // Account section
          _Section(
            title: 'ACCOUNT',
            rows: [
              _InfoRow(icon: Icons.mail_rounded, label: 'Email', value: email),
              _InfoRow(icon: Icons.call_rounded, label: 'Phone', value: '+91 98100 23456', mono: true),
              _InfoRow(icon: Icons.lock_reset_rounded, label: 'Change Password', value: '', tappable: true),
              _InfoRow(
                icon: Icons.print_rounded, label: 'Printer Settings',
                value: '3 KOT PRINTERS CONNECTED',
                valueColor: AppTheme.primaryContainer, tappable: true,
              ),
            ],
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 32),
          // Sign out
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () async {
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
                if (context.mounted) context.go('/role-select');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Sign Out',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text('DELETE ACCOUNT',
                  style: GoogleFonts.inter(
                    fontSize: 11, fontWeight: FontWeight.w500,
                    color: AppTheme.secondary.withValues(alpha: 0.6), letterSpacing: 0.5,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String initials;
  const _HeroCard({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh, shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surface, width: 4),
                ),
                child: Center(
                  child: Text(initials,
                      style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.primaryContainer)),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surface, width: 2)),
                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Vikram Sharma',
              style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
          const SizedBox(height: 4),
          Text('Owner · The Grand Spice',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.secondary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: AppTheme.radiusFull,
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
            ),
            child: Text('PRO PLAN',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFB91C1C), letterSpacing: 1.2)),
          ),
        ],
      ),
    );
  }
}

class _PlanBanner extends StatelessWidget {
  const _PlanBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF2F2),
        borderRadius: BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
        border: Border(left: BorderSide(color: AppTheme.primaryContainer, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PLAN', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text('PRO PLAN ACTIVE', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
            Text('Billed annually. Next renewal Sept 2025.',
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.secondary)),
          ]),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer, foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Upgrade', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  const _Section({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppTheme.surfaceContainerLow,
            child: Text(title,
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.secondary, letterSpacing: 1.5)),
          ),
          ...rows.expand((r) => [r, Divider(color: AppTheme.surfaceContainerLow, thickness: 1, height: 1)]),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;
  final bool tappable;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value,
      this.mono = false, this.tappable = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: tappable ? () {} : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.secondary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: value.isEmpty
                  ? Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.onSurface))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.secondary)),
                        const SizedBox(height: 2),
                        mono
                            ? Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppTheme.onSurface))
                            : Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500,
                                color: valueColor ?? AppTheme.onSurface)),
                      ],
                    ),
            ),
            if (tappable) const Icon(Icons.chevron_right_rounded, color: AppTheme.surfaceDim, size: 20),
          ],
        ),
      ),
    );
  }
}
