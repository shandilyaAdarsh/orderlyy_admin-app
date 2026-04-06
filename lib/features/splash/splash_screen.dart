import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
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

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      context.go('/admin/dashboard');
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
          // ── Decorative texture background icons ──────────────────────────
          Positioned(
            top: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Icon(
                Icons.deck_outlined,
                size: 200,
                color: AppTheme.onSurface.withValues(alpha: 0.025),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 160,
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
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring (O)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                            width: 6,
                          ),
                        ),
                      ),
                      // Icon
                      Icon(
                        Icons.restaurant_menu_rounded,
                        size: 36,
                        color: AppTheme.primaryContainer,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 24),

                // Wordmark
                Text(
                  'TableOS',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(
                      begin: 0.2,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 6),

                // Tagline
                Text(
                  'RESTAURANT INTELLIGENCE PLATFORM',
                  style: GoogleFonts.inter(
                    fontSize: 10,
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
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 240,
                child: Column(
                  children: [
                    // Progress line
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9999),
                      child: SizedBox(
                        height: 2,
                        child: AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, _) {
                            return LinearProgressIndicator(
                              value: _progressController.value,
                              backgroundColor:
                                  AppTheme.surfaceContainerHighest,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryContainer,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Version
                    Text(
                      'v1.0.0',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
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
