import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

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
    debugPrint(
      '[TRACE] [Splash Init] Displaying splash UI. Waiting for GoRouter redirect...',
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryRed = const Color(0xFFE31E24);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Ambient background effect ─────────────────────────────────────
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Center(
                child: Container(
                  width: 800.r,
                  height: 800.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryRed,
                        Colors.transparent,
                      ],
                      radius: 0.6,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Central Logo Area ─────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon/Logo Graphic
                Transform.rotate(
                  angle: 12 * 3.1415926535 / 180, // 12 degrees
                  child: Container(
                    width: 96.r,
                    height: 96.r,
                    decoration: BoxDecoration(
                      color: primaryRed,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: primaryRed.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.restaurant_rounded,
                      size: 48.r,
                      color: Colors.white,
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  curve: Curves.easeOutBack,
                ),

                SizedBox(height: 24.h),

                // Brand Name
                Text(
                  'Orderlyy',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF191C1D),
                    letterSpacing: -1.0,
                  ),
                )
                .animate(delay: 200.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.2, curve: Curves.easeOut),
              ],
            ),
          ),

          // ── Bottom Tagline Area ───────────────────────────────────────────
          Positioned(
            bottom: 48.h,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'One app is enough for restaurant',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5D3F3C).withOpacity(0.8),
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
