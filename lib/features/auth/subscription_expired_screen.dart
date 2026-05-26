import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/mock_auth_provider.dart';
import '../../core/providers/repository_providers.dart';

class SubscriptionExpiredScreen extends ConsumerWidget {
  const SubscriptionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80.r,
                  height: 80.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(
                    Icons.credit_card_off_rounded,
                    size: 42.r,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                SizedBox(height: 28.h),

                // Title
                Text(
                  'Subscription Expired',
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 12.h),

                // Description
                Text(
                  'Your subscription has expired. Please renew your plan to continue using the admin dashboard.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: AppTheme.secondary,
                    height: 1.6,
                  ),
                ),
                SizedBox(height: 36.h),

                // Sign out button
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: OutlinedButton(
                    onPressed: () async {
                      final repo = ref.read(authRepositoryProvider);
                      await repo.signOut();
                      ref.read(appContextProvider.notifier).clearContext();
                      if (context.mounted) context.go('/admin/login');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondary,
                      side: BorderSide(color: AppTheme.surfaceContainerHigh),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'Sign Out',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
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
