import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/app_context_provider.dart';
import '../../core/theme/app_theme.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  // Password form
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  // Phone OTP form
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final bool _showPhonePanel = false;

  // Shared state
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ── Email + Password Login ─────────────────────────────────────────────────
  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.signInWithPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (response.user != null) {
        // Step 2: resolve tenant context immediately after login
        final ctx = await ref
            .read(appContextProvider.notifier)
            .resolveContext();
        if (ctx == null) {
          if (mounted) {
            context.go('/admin/login');
          }
          return;
        }
        if (mounted) {
          _routeFromFlags(
            ctx.flags.mustChangePassword,
            ctx.flags.subscriptionExpired,
            !ctx.tenant.isActive,
            ctx.flags.onboardingRequired,
          );
        }
      } else {
        setState(() => _errorMessage = 'Login failed. Please try again.');
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('AuthApiException: ', ''),
      );
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 1,
        shadowColor: AppTheme.surfaceContainerHigh,
        toolbarHeight: 64.h,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: 24.r),
          onPressed: () => context.pop(),
          color: AppTheme.secondary,
        ),
        title: Text(
          'Admin Login',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryContainer,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Text(
              'Orderlli',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryContainer,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Branding ──────────────────────────────────────────────────
                    _buildBrandingSection(),
                    SizedBox(height: 32.h),
                    // ── ID + Password form ─────────────────────────────────────────
                    _buildIdPasswordCard(),
                    SizedBox(height: 24.h),

                    // ── Footer ────────────────────────────────────────────────────
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingSection() {
    return Column(
      children: [
        Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.shield_rounded,
                size: 48.r,
                color: AppTheme.primaryContainer,
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
        SizedBox(height: 16.h),
        Text(
          'Welcome back',
          style: GoogleFonts.inter(
            fontSize: 26.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
        SizedBox(height: 4.h),
        Text(
          'Sign in to manage your restaurant',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.secondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
      ],
    );
  }

  Widget _buildIdPasswordCard() {
    return Container(
      padding: EdgeInsets.all(24.r),
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
            // Card header
            Row(
              children: [
                Icon(
                  Icons.key_rounded,
                  color: AppTheme.primaryContainer,
                  size: 20.r,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Email & Password',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Error banner
            if (_errorMessage.isNotEmpty && !_showPhonePanel) ...[
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
                hintStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 14.sp,
                  color: AppTheme.secondary.withValues(alpha: 0.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                filled: true,
                fillColor: AppTheme.surface,
                border: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.surfaceContainerHigh,
                    width: 2.w,
                  ),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.surfaceContainerHigh,
                    width: 2.w,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.primaryContainer,
                    width: 2.w,
                  ),
                ),
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
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot?',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryContainer,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: GoogleFonts.inter(fontSize: 14.sp, color: AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppTheme.secondary.withValues(alpha: 0.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                filled: true,
                fillColor: AppTheme.surface,
                border: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.surfaceContainerHigh,
                    width: 2.w,
                  ),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.surfaceContainerHigh,
                    width: 2.w,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.primaryContainer,
                    width: 2.w,
                  ),
                ),
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
                if (v.length < 6) return 'Password must be at least 6 chars';
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
                  elevation: 0,
                  shadowColor: AppTheme.primary.withValues(alpha: 0.3),
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
                          Flexible(
                            child: Text(
                              'Login to Dashboard',
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
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
    ).animate(delay: 350.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildFooter() {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.inter(fontSize: 14.sp, color: AppTheme.secondary),
        children: [
          const TextSpan(text: 'Having trouble? '),
          TextSpan(
            text: 'Contact Support',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryContainer,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.primaryContainer.withValues(alpha: 0.4),
              decorationThickness: 2,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    ).animate(delay: 400.ms).fadeIn(duration: 400.ms);
  }
}

// ── Method Button (flat card style) ───────────────────────────────────────────
class _MethodButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _MethodButton({required this.child, required this.onTap});

  @override
  State<_MethodButton> createState() => _MethodButtonState();
}

class _MethodButtonState extends State<_MethodButton> {
  bool _hovered = false;
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
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            height: 52.h,
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            decoration: BoxDecoration(
              color: _hovered
                  ? AppTheme.surfaceContainerLow
                  : AppTheme.surfaceContainerLowest,
              borderRadius: AppTheme.radiusXl,
              boxShadow: AppTheme.crimsonShadowLight,
            ),
            alignment: Alignment.centerLeft,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
