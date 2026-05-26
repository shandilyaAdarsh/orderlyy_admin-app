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
  bool _isLoading = false;
  String _errorMessage = '';

  // Controls entrance flow stage: false -> Laptop Landing, true -> standard login form
  bool _showLoginForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
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
      backgroundColor: _showLoginForm ? const Color(0xFFF8F9FA) : AppTheme.background,
      appBar: AppBar(
        backgroundColor: _showLoginForm ? const Color(0xFFF8F9FA) : AppTheme.surfaceContainerLowest,
        elevation: 0,
        toolbarHeight: 68.h,
        automaticallyImplyLeading: false,
        leading: _showLoginForm
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16.r, color: AppTheme.secondary),
                onPressed: () => setState(() {
                  _showLoginForm = false;
                  _errorMessage = '';
                }),
              )
            : null,
        title: Row(
          children: [
            // Brand Cutlery Icon
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: primaryRed.withOpacity(0.08),
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
        actions: const [],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
          child: _showLoginForm ? _buildLoginScreen(primaryRed) : _buildLaptopScreen(primaryRed),
        ),
      ),
    );
  }

  // ── FUNNEL STAGE 1: Laptop mockup landing screen ──────────────────────────
  Widget _buildLaptopScreen(Color primaryRed) {
    return Center(
      key: const ValueKey('LaptopScreen'),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hero Section Header
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
                  // Main mockup asset
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDSyJ4bjHLNYS3SWZiFZnqOzMpqKyhb6htk3bfvmqumyuV61sy3oel_-V9G0H27eXIM_iH75Cx8VLD56b4cyhDqTcz3DOZFe5pdZwgH8nSYsUsC_x4N0zoDIHtaAVV0uQQ0jOOrNDPIBR3Hylw2CKTmtbJctj_sgR2f5pOh-QFOL3qw90R7DHqBG-r7SqRsFITwcTV3hfBQLpp-gWzzQgab0c1ChjAbHsRKeCtIld79NXoHQUNEbRm5jrmUsL1NbDzSBrDipKqbR15MuU0',
                      height: 270.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                  
                  // Floating notification mockup overlay
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
                            color: Colors.black.withOpacity(0.06),
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
                            onPressed: () {}, // Passive Overlay Button
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

              SizedBox(height: 24.h),

              // Feature cards lined in a Row (Passive descriptive blocks)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHorizontalCard(
                    icon: Icons.videocam_outlined,
                    label: 'Live\nOrders',
                  ),
                  _buildHorizontalCard(
                    icon: Icons.assignment_outlined,
                    label: 'Order\nList',
                  ),
                  _buildHorizontalCard(
                    icon: Icons.analytics_outlined,
                    label: 'Sales &\nAnalytics',
                  ),
                  _buildHorizontalCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'Inventory',
                  ),
                  _buildHorizontalCard(
                    icon: Icons.people_outline_rounded,
                    label: 'Customers',
                  ),
                ],
              ).animate().fadeIn(delay: 250.ms),

              SizedBox(height: 24.h),

              // Subtext Section
              Center(
                child: Text(
                  'Manage orders and track your\nbusiness on the go! Orderlyy',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                    height: 1.4,
                  ),
                ),
              ).animate().fadeIn(delay: 280.ms),

              SizedBox(height: 20.h),

              // Primary CTA
              SizedBox(
                height: 52.h,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showLoginForm = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Login / Sign Up',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),

              SizedBox(height: 16.h),

              // Footer Subtext
              Center(
                child: Text(
                  'One app is enough for restaurant',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondary.withOpacity(0.6),
                  ),
                ),
              ).animate().fadeIn(delay: 350.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalCard({
    required IconData icon,
    required String label,
  }) {
    final primaryRed = const Color(0xFFE31E24);
    
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFF1F5F9)), // slate 100
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: primaryRed,
              size: 20.r,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B), // slate 800
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FUNNEL STAGE 2: Standard Credential Sign-in Card ───────────────────────
  Widget _buildLoginScreen(Color primaryRed) {
    return Center(
      key: const ValueKey('LoginScreen'),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400.w),
            child: Container(
              padding: EdgeInsets.all(28.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Title
                    Center(
                      child: Text(
                        'Orderlyy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 40.sp,
                          fontWeight: FontWeight.w800,
                          color: primaryRed,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    
                    // Welcome Back Heading
                    Center(
                      child: Text(
                        'Welcome Back',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF191C1D),
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    
                    // Sign-in Subheading
                    Center(
                      child: Text(
                        'Sign in to manage your restaurant operations securely.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5D5E61),
                          height: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Error Notification Banner
                    if (_errorMessage.isNotEmpty) ...[
                      Container(
                        margin: EdgeInsets.only(bottom: 16.h),
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withOpacity(0.3),
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
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Email Address Label
                    Text(
                      'Email Address',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF191C1D),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        color: const Color(0xFF191C1D),
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.mail_outline_rounded,
                          color: const Color(0xFF5D5E61),
                          size: 20.r,
                        ),
                        hintText: 'name@restaurant.com',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 14.sp,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: primaryRed),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter email';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    SizedBox(height: 18.h),

                    // Password Label & Forgot Password Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Password',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF191C1D),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Forgot Password Action (Dialog/Reset Call)
                          },
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: primaryRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.sp,
                        color: const Color(0xFF191C1D),
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: const Color(0xFF5D5E61),
                          size: 20.r,
                        ),
                        hintText: '••••••••',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 14.sp,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF5D5E61),
                            size: 20.r,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: primaryRed),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter your password';
                        return null;
                      },
                      onFieldSubmitted: (_) => _loginWithPassword(),
                    ),
                    SizedBox(height: 24.h),

                    // Primary Login Button (Arrow Forward Action)
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _loginWithPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
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
                                    'Login',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18.r,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
