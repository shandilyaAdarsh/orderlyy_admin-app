import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/mock_auth_provider.dart';

// ── SplashScreen ──────────────────────────────────────────────────────────────
// In mock mode: checks mock auth state only.
// No Supabase.instance references.

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash animation
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final currentUserId = ref.read(currentUserIdProvider);

    if (currentUserId != null) {
      // Resolve mock context to determine routing flags
      final resolvedCtx =
          await ref.read(appContextProvider.notifier).resolveContext();
      if (!mounted) return;

      if (resolvedCtx == null) {
        context.go('/role-select');
        return;
      }

      final flags = resolvedCtx.flags;
      if (flags.mustChangePassword) {
        context.go('/change-password');
      } else if (flags.subscriptionExpired) {
        context.go('/subscription-expired');
      } else if (flags.accountSuspended) {
        context.go('/account-suspended');
      } else if (!resolvedCtx.onboarding.isComplete ||
          flags.onboardingRequired) {
        context.go('/onboarding');
      } else {
        context.go('/admin/dashboard');
      }
    } else {
      context.go('/role-select');
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      body: Stack(
        children: [
          // ── Decorative background icons ──────────────────────────────────
          Positioned(
            top: -20.h,
            right: -20.w,
            child: Padding(
              padding: EdgeInsets.all(48.r),
              child: Icon(
                Icons.deck_outlined,
                size: 200.r,
                color: AppTheme.onSurface.withValues(alpha: 0.025),
              ),
            ),
          ),
          Positioned(
            bottom: -20.h,
            left: -20.w,
            child: Padding(
              padding: EdgeInsets.all(48.r),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 160.r,
                color: AppTheme.onSurface.withValues(alpha: 0.025),
              ),
            ),
          ),

          // ── Main branding cluster ─────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo mark
                SizedBox(
                      width: 64.r,
                      height: 64.r,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 64.r,
                            height: 64.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryContainer.withValues(
                                  alpha: 0.1,
                                ),
                                width: 6.r,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.restaurant_menu_rounded,
                            size: 36.r,
                            color: AppTheme.primaryContainer,
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOutBack,
                    ),

                SizedBox(height: 24.h),

                Text(
                      'Orderlli',
                      style: GoogleFonts.inter(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOut),

                SizedBox(height: 6.h),

                Text(
                  'RESTAURANT INTELLIGENCE PLATFORM',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.secondary.withValues(alpha: 0.7),
                    letterSpacing: 2.0,
                  ),
                ).animate(delay: 300.ms).fadeIn(duration: 500.ms),
              ],
            ),
          ),

          // ── Progress bar + version ────────────────────────────────────────
          Positioned(
            bottom: 48.h,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 240.w,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9999.r),
                      child: SizedBox(
                        height: 2.h,
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, _) {
                            return LinearProgressIndicator(
                              value: _progressController.value,
                              backgroundColor: AppTheme.surfaceContainerHighest,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryContainer,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'v1.0.0 • mock mode',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.sp,
                        color: AppTheme.secondary.withValues(alpha: 0.5),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
          ),
        ],
      ),
    );
  }
}
