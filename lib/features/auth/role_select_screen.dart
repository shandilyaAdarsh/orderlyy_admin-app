import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // ── Subtle glass orbs ─────────────────────────────────────────────
          Positioned(
            top: -64.r,
            right: -64.r,
            child: Container(
              width: 256.r,
              height: 256.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ).animate().scale(
            begin: const Offset(0.5, 0.5),
            duration: 800.ms,
            curve: Curves.easeOut,
          ),
          Positioned(
            bottom: -64.r,
            left: -64.r,
            child: Container(
              width: 256.r,
              height: 256.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.tertiaryContainer.withValues(alpha: 0.05),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Top section ──────────────────────────────────────────
                    SizedBox(height: 48.h),
                    Icon(
                          Icons.restaurant_menu_rounded,
                          size: 32.r,
                          color: AppTheme.primary,
                        )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .scale(
                          begin: const Offset(0.6, 0.6),
                          curve: Curves.easeOutBack,
                        ),

                    SizedBox(height: 24.h),

                    Text(
                          'Welcome to Orderlli',
                          style: GoogleFonts.inter(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.15, curve: Curves.easeOut),

                    SizedBox(height: 40.h),

                    // ── Role cards ────────────────────────────────────────────
                    // Admin / Owner card
                    _RoleCard(
                          icon: Icons.admin_panel_settings_rounded,
                          title: 'Admin / Owner',
                          subtitle: 'Full restaurant control',
                          iconBgColor: AppTheme.primaryContainer.withValues(
                            alpha: 0.08,
                          ),
                          iconColor: AppTheme.primaryContainer,
                          borderColor: AppTheme.primaryContainer,
                          arrowColor: AppTheme.primaryContainer,
                          onTap: () => context.push('/admin/login'),
                        )
                        .animate(delay: 250.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, curve: Curves.easeOut),

                    SizedBox(height: 16.h),

                    // Staff card
                    _RoleCard(
                          icon: Icons.groups_rounded,
                          title: 'Staff',
                          subtitle: 'Waiter · Manager',
                          iconBgColor: AppTheme.surfaceContainerLow,
                          iconColor: AppTheme.secondary,
                          borderColor: AppTheme.secondaryContainer,
                          arrowColor: AppTheme.secondary,
                          onTap: () => context.push('/staff/login'),
                        )
                        .animate(delay: 350.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, curve: Curves.easeOut),

                    SizedBox(height: 32.h),

                    // ── Footer ────────────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.only(bottom: 32.h),
                      child: Column(
                        children: [
                          Text(
                            'POWERED BY',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.secondary.withValues(alpha: 0.6),
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Orderlli',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.secondary.withValues(alpha: 0.8),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role Card ─────────────────────────────────────────────────────────────────
class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBgColor;
  final Color iconColor;
  final Color borderColor;
  final Color arrowColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBgColor,
    required this.iconColor,
    required this.borderColor,
    required this.arrowColor,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: AppTheme.radiusXl,
            border: Border(
              left: BorderSide(color: widget.borderColor, width: 3.w),
            ),
            boxShadow: AppTheme.crimsonShadow,
          ),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.iconBgColor,
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 22.r),
              ),
              SizedBox(width: 20.w),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Arrow
              Icon(
                Icons.arrow_forward_rounded,
                color: widget.arrowColor,
                size: 20.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
