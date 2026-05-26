import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth/mock_auth_provider.dart';
import '../../core/theme/app_theme.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? '';

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (profile) {
        final tenant = profile?['tenants'] as Map<String, dynamic>?;
        final name = profile?['name'] ?? 'Admin User';
        final initials = name.isNotEmpty ? name[0].toUpperCase() : 'A';
        final restaurantName = tenant?['name'] ?? 'Your Restaurant';
        final location = tenant?['address'] ?? 'Location not set';

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.surfaceContainerLowest,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 64.h,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.secondary,
                size: 24.r,
              ),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Orderlli',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.secondary,
                  size: 24.r,
                ),
                onPressed: () {},
              ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 120.h),
            children: [
              // Hero
              _HeroCard(
                name: name,
                role: 'Owner · $restaurantName',
                initials: initials,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              SizedBox(height: 16.h),
              // Plan banner
              _PlanBanner().animate(delay: 100.ms).fadeIn(duration: 400.ms),
              SizedBox(height: 16.h),
              // Restaurant section
              _Section(
                title: 'RESTAURANT',
                rows: [
                  _InfoRow(
                    icon: Icons.storefront_rounded,
                    label: 'Name',
                    value: restaurantName,
                  ),
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    label: 'Location',
                    value: location,
                  ),
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Operating Hours',
                    value: '11:00 AM – 11:30 PM',
                  ),
                  _InfoRow(
                    icon: Icons.grid_view_rounded,
                    label: 'Tables',
                    value: 'Active System',
                    mono: true,
                  ),
                ],
              ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
              SizedBox(height: 16.h),
              // Account section
              _Section(
                title: 'ACCOUNT',
                rows: [
                  _InfoRow(
                    icon: Icons.mail_rounded,
                    label: 'Email',
                    value: email,
                  ),
                  _InfoRow(
                    icon: Icons.call_rounded,
                    label: 'Phone',
                    value: profile?['phone'] ?? 'Not set',
                    mono: true,
                  ),
                  _InfoRow(
                    icon: Icons.lock_reset_rounded,
                    label: 'Change Password',
                    value: '',
                    tappable: true,
                  ),
                  _InfoRow(
                    icon: Icons.print_rounded,
                    label: 'Printer Settings',
                    value: 'CLoud Printing Active',
                    valueColor: AppTheme.primaryContainer,
                    tappable: true,
                  ),
                ],
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
              SizedBox(height: 32.h),
              // Sign out
              SizedBox(
                height: 52.h,
                child: OutlinedButton(
                  onPressed: () async {
                    final authService = ref.read(authServiceProvider);
                    await authService.signOut();
                    if (context.mounted) context.go('/admin/login');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: BorderSide(color: AppTheme.primary, width: 2.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    'Sign Out',
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
              SizedBox(height: 12.h),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'DELETE ACCOUNT',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.secondary.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String name;
  final String role;
  final String initials;
  const _HeroCard({
    required this.name,
    required this.role,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
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
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surface, width: 4.w),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryContainer,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surface, width: 2.w),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 12.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            role,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: AppTheme.secondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: AppTheme.radiusFull,
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              'PRO PLAN',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFB91C1C),
                letterSpacing: 1.2,
              ),
            ),
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
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12.r),
          bottomRight: Radius.circular(12.r),
        ),
        border: Border(
          left: BorderSide(color: AppTheme.primaryContainer, width: 4.w),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLAN',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'PRO PLAN ACTIVE',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Billed annually. Next renewal Sept 2025.',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              elevation: 0,
            ),
            child: Text(
              'Upgrade',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
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
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            color: AppTheme.surfaceContainerLow,
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                color: AppTheme.secondary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          ...rows.expand(
            (r) => [
              r,
              Divider(
                color: AppTheme.surfaceContainerLow,
                thickness: 1,
                height: 1.h,
              ),
            ],
          ),
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
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
    this.tappable = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: tappable ? () {} : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.secondary, size: 22.r),
            SizedBox(width: 16.w),
            Expanded(
              child: value.isEmpty
                  ? Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: AppTheme.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        mono
                            ? Text(
                                value,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 13.sp,
                                  color: AppTheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(
                                value,
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: valueColor ?? AppTheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ],
                    ),
            ),
            if (tappable)
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.surfaceDim,
                size: 20.r,
              ),
          ],
        ),
      ),
    );
  }
}
