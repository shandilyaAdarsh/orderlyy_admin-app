import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth/mock_auth_provider.dart';
import '../../core/data/dtos/auth_dto.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_theme.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailController = TextEditingController(text: 'admin@orderlli.in');
  final _passwordController = TextEditingController(text: 'password123');
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _showManualCredentials = false;

  // Shared state
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Authentication Trigger (standard flow) ─────────────────────────────────
  Future<void> _loginWithPassword() async {
    if (_showManualCredentials && !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.signInWithPassword(
        LoginRequestDto(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
      if (response.isSuccess) {
        final ctx = await ref
            .read(appContextProvider.notifier)
            .resolveContext();
        if (ctx == null) {
          if (mounted) context.go('/admin/login');
          return;
        }
        if (mounted) {
          _routeFromFlags(
            ctx.flags.mustChangePassword,
            ctx.flags.subscriptionExpired,
            ctx.flags.accountSuspended,
            ctx.flags.onboardingRequired,
          );
        }
      } else {
        setState(
          () => _errorMessage =
              response.errorMessage ?? 'Login failed. Please try again.',
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Route helper based on flags ────────────────────────────────────────────
  void _routeFromFlags(
    bool mustChangePw,
    bool subExpired,
    bool suspended,
    bool onboardRequired,
  ) {
    if (mustChangePw) {
      context.go('/change-password');
    } else if (subExpired) {
      context.go('/subscription-expired');
    } else if (suspended) {
      context.go('/account-suspended');
    } else if (onboardRequired) {
      context.go('/onboarding');
    } else {
      context.go('/admin/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryRed = const Color(0xFFE31E24);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        toolbarHeight: 68.h,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Custom Logo SVG-like Mark
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: primaryRed.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: 18.r,
                color: primaryRed,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'Orderlyy',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: primaryRed,
              ),
            ),
          ],
        ),
        actions: [
          if (!_showManualCredentials)
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: TextButton.icon(
                onPressed: () => setState(() => _showManualCredentials = true),
                icon: Icon(Icons.lock_open_rounded, size: 14.r, color: AppTheme.secondary),
                label: Text(
                  'Custom Sign In',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_showManualCredentials) ...[
                      // ── LANDING EXPANSION MODE ─────────────────────────────────
                      
                      // Hero Section
                      Center(
                        child: Text(
                          'Welcome to Orderlyy - Your\nRestaurant Software',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                      
                      SizedBox(height: 24.h),

                      // Tablet Mockup and Floating Alert
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Main mockups
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: Image.network(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuDSyJ4bjHLNYS3SWZiFZnqOzMpqKyhb6htk3bfvmqumyuV61sy3oel_-V9G0H27eXIM_iH75Cx8VLD56b4cyhDqTcz3DOZFe5pdZwgH8nSYsUsC_x4N0zoDIHtaAVV0uQQ0jOOrNDPIBR3Hylw2CKTmtbJctj_sgR2f5pOh-QFOL3qw90R7DHqBG-r7SqRsFITwcTV3hfBQLpp-gWzzQgab0c1ChjAbHsRKeCtIld79NXoHQUNEbRm5jrmUsL1NbDzSBrDipKqbR15MuU0',
                              height: 180.h,
                              fit: BoxFit.contain,
                            ),
                          ),
                          
                          // Floating notification card
                          Positioned(
                            bottom: -10.h,
                            right: 0,
                            child: Container(
                              width: 170.w,
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 6.r,
                                        height: 6.r,
                                        decoration: BoxDecoration(
                                          color: primaryRed,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'New Order Received',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w800,
                                          color: primaryRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    'Table 4 • #ORD-882',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    '1 x Spicy Paneer Burger\n1 x Masala Fries',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.sp,
                                      color: const Color(0xFF64748B),
                                      height: 1.3,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _loginWithPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryRed,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      minimumSize: Size(double.infinity, 28.h),
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                    ),
                                    child: Text(
                                      'View Order',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                          )
                        ],
                      ).animate().fadeIn(duration: 500.ms),

                      SizedBox(height: 36.h),

                      // Feature interactive grid
                      Text(
                        'Explore Live Features',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.secondary,
                          letterSpacing: 0.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      SizedBox(height: 10.h),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.r,
                        mainAxisSpacing: 12.r,
                        childAspectRatio: 1.45,
                        children: [
                          _buildFeatureCard(
                            icon: Icons.notifications_active_outlined,
                            title: 'Live KDS Feed',
                            desc: 'Active orders feed',
                            onTap: _loginWithPassword,
                          ),
                          _buildFeatureCard(
                            icon: Icons.trending_up_rounded,
                            title: 'Sales & Metrics',
                            desc: 'Realtime analytics',
                            onTap: _loginWithPassword,
                          ),
                          _buildFeatureCard(
                            icon: Icons.restaurant_menu_rounded,
                            title: 'Menu Manager',
                            desc: 'Instant availability',
                            onTap: _loginWithPassword,
                          ),
                          _buildFeatureCard(
                            icon: Icons.inventory_2_outlined,
                            title: 'Stock Control',
                            desc: 'Low stock alerts',
                            onTap: _loginWithPassword,
                          ),
                        ],
                      ).animate().fadeIn(delay: 250.ms),

                      SizedBox(height: 32.h),

                      // Primary CTA
                      SizedBox(
                        height: 52.h,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _loginWithPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 20.r,
                                  height: 20.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Login to Live Dashboard',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Icon(Icons.arrow_forward_rounded, size: 16.r),
                                  ],
                                ),
                        ),
                      ).animate().fadeIn(delay: 300.ms),

                      SizedBox(height: 24.h),

                      // Footer Subtext
                      Center(
                        child: Text(
                          'One app is enough for your entire restaurant.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondary.withValues(alpha: 0.6),
                          ),
                        ),
                      ).animate().fadeIn(delay: 350.ms),
                    ] else ...[
                      // ── MANUAL PASSWORD LOGIN FORM MODE ─────────────────────────
                      _buildManualLoginFormHeader(),
                      SizedBox(height: 28.h),
                      _buildIdPasswordCard(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    final primaryRed = const Color(0xFFE31E24);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: AppTheme.crimsonShadowLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: primaryRed.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                color: primaryRed,
                size: 18.r,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
              ),
            ),
            Text(
              desc,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: AppTheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualLoginFormHeader() {
    return Column(
      children: [
        IconButton(
          onPressed: () => setState(() => _showManualCredentials = false),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16.r, color: AppTheme.secondary),
        ),
        SizedBox(height: 12.h),
        Text(
          'Custom Session Login',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: AppTheme.onSurface,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Sign in with custom administrative credentials',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: AppTheme.secondary,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildIdPasswordCard() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusXl,
        border: Border(
          left: BorderSide(color: AppTheme.primaryContainer, width: 3.w),
        ),
        boxShadow: AppTheme.crimsonShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error banner
            if (_errorMessage.isNotEmpty) ...[
              Container(
                margin: EdgeInsets.only(bottom: 16.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: const Color(0xFFEF4444),
                      size: 16.r,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: const Color(0xFFEF4444),
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Email
            Text(
              'Email Address',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.secondary,
              ),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14.sp,
                color: AppTheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'admin@orderlli.in',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                filled: true,
                fillColor: AppTheme.surface,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            SizedBox(height: 20.h),

            // Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Password',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppTheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: '••••••••',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                filled: true,
                fillColor: AppTheme.surface,
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.secondary,
                    size: 20.r,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your password';
                return null;
              },
              onFieldSubmitted: (_) => _loginWithPassword(),
            ),
            SizedBox(height: 24.h),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loginWithPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Login to Dashboard',
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(Icons.login_rounded, size: 18.r),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}
