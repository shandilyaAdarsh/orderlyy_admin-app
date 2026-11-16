import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/data/dtos/auth_dto.dart';
import '../../core/network/api_exception.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final request = LoginRequestDto(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final result = await authRepo.signInWithPassword(request);
      if (result is Failure) {
        throw Exception((result as Failure).error.message);
      }
      // Router will redirect based on new auth state — no manual navigation needed.
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 48.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo / Icon ───────────────────────────────────────────
                  Container(
                    width: 64.r,
                    height: 64.r,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      size: 36.r,
                      color: AppTheme.primaryContainer,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ── Heading ───────────────────────────────────────────────
                  Text(
                    'Admin Portal',
                    style: GoogleFonts.inter(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Sign in to manage your restaurant operations.',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppTheme.secondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 36.h),

                  // ── Form ──────────────────────────────────────────────────
                  Form(
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
                                    style: GoogleFonts.inter(
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
                          'Email',
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
                          textInputAction: TextInputAction.next,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: AppTheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'admin@restaurant.com',
                            hintStyle: GoogleFonts.inter(
                              color: AppTheme.secondary.withValues(alpha: 0.5),
                              fontSize: 14.sp,
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
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: const Color(0xFFEF4444),
                                width: 2.w,
                              ),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: const Color(0xFFEF4444),
                                width: 2.w,
                              ),
                            ),
                          ),
                          validator: _validateEmail,
                        ),
                        SizedBox(height: 20.h),

                        // Password
                        Text(
                          'Password',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.secondary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: AppTheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: GoogleFonts.inter(
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
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: const Color(0xFFEF4444),
                                width: 2.w,
                              ),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: const Color(0xFFEF4444),
                                width: 2.w,
                              ),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppTheme.secondary,
                                size: 20.r,
                              ),
                            ),
                          ),
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),
                        SizedBox(height: 32.h),

                        // Sign in button
                        SizedBox(
                          width: double.infinity,
                          height: 52.h,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryContainer,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppTheme.primaryContainer.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
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
                                : Text(
                                    'Sign In',
                                    style: GoogleFonts.inter(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Verify Sentry Setup button
                        SizedBox(
                          width: double.infinity,
                          height: 44.h,
                          child: ElevatedButton(
                            onPressed: () async {
                              await Sentry.captureMessage('Verify Sentry Setup: test event');
                              throw StateError('This is test exception');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E384D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              elevation: 0,
                            ),
                            child: const Text('Verify Sentry Setup'),
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // ── Footer ────────────────────────────────────────────────
                  Center(
                    child: Text(
                      'Orderlyy Admin · Secure Access',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppTheme.secondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}