import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth/auth_provider.dart';
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
  bool _showPhonePanel = false;
  bool _showOTPField = false;

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
        if (mounted) context.go('/admin/dashboard');
      } else {
        setState(() => _errorMessage = 'Login failed. Please try again.');
      }
    } catch (e) {
      setState(() =>
          _errorMessage = e.toString().replaceAll('AuthApiException: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Send Phone OTP ─────────────────────────────────────────────────────────
  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter phone number');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendOTP('+91${_phoneController.text.trim()}');
      setState(() => _showOTPField = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      setState(
          () => _errorMessage = 'Failed to send OTP. Check phone number.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Verify Phone OTP ───────────────────────────────────────────────────────
  Future<void> _verifyOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.verifyOTP(
        '+91${_phoneController.text.trim()}',
        _otpController.text.trim(),
      );
      if (response.user != null) {
        if (mounted) context.go('/admin/dashboard');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Invalid OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
          color: AppTheme.secondary,
        ),
        title: Text(
          'Admin Login',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryContainer,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'TableOS',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryContainer,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // ── Branding ──────────────────────────────────────────────────
              _buildBrandingSection(),
              const SizedBox(height: 32),

              // ── Login method cards ─────────────────────────────────────────
              _buildGoogleButton(),
              const SizedBox(height: 12),
              _buildPhoneButton(),
              const SizedBox(height: 24),

              // ── Phone OTP panel ────────────────────────────────────────────
              if (_showPhonePanel) ...[
                _buildPhoneOtpCard(),
                const SizedBox(height: 24),
              ],

              // ── OR Divider ────────────────────────────────────────────────
              _buildDivider(),
              const SizedBox(height: 24),

              // ── ID + Password form ─────────────────────────────────────────
              _buildIdPasswordCard(),
              const SizedBox(height: 24),

              // ── Footer ────────────────────────────────────────────────────
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingSection() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.shield_rounded,
            size: 48,
            color: AppTheme.primaryContainer,
          ),
        ).animate().fadeIn(duration: 500.ms).scale(
              begin: const Offset(0.8, 0.8),
              curve: Curves.easeOutBack,
            ),
        const SizedBox(height: 16),
        Text(
          'Welcome back',
          style: GoogleFonts.inter(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
            letterSpacing: -0.5,
          ),
        ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 4),
        Text(
          'Sign in to manage your restaurant',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.secondary,
          ),
        ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return _MethodButton(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in coming soon')),
        );
      },
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Image.network(
              'https://www.google.com/favicon.ico',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.g_mobiledata_rounded,
                color: Color(0xFF4285F4),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Continue with Google',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildPhoneButton() {
    return _MethodButton(
      onTap: () {
        setState(() {
          _showPhonePanel = !_showPhonePanel;
          _errorMessage = '';
        });
      },
      child: Row(
        children: [
          Icon(
            Icons.smartphone_rounded,
            color: _showPhonePanel
                ? AppTheme.primaryContainer
                : AppTheme.secondary,
            size: 22,
          ),
          const SizedBox(width: 16),
          Text(
            _showPhonePanel
                ? 'Hide Phone Login'
                : 'Continue with Phone Number',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildPhoneOtpCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusXl,
        border: Border(
          left: BorderSide(color: const Color(0xFF059669), width: 3),
        ),
        boxShadow: AppTheme.crimsonShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_rounded,
                  color: Color(0xFF059669), size: 20),
              const SizedBox(width: 10),
              Text(
                'Phone OTP Login',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Error banner
          if (_errorMessage.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                          color: Color(0xFFEF4444), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Phone field
          Text(
            'Mobile Number',
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.secondary),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 14, color: AppTheme.onSurface),
            decoration: InputDecoration(
              prefixText: '+91 ',
              prefixStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 14, color: AppTheme.onSurface),
              hintText: '9876543210',
              hintStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  color: AppTheme.secondary.withValues(alpha: 0.5)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: AppTheme.surface,
              border: const UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: AppTheme.surfaceContainerHigh, width: 2)),
              enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: AppTheme.surfaceContainerHigh, width: 2)),
              focusedBorder: const UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: Color(0xFF059669), width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          // OTP field (shown after OTP sent)
          if (_showOTPField) ...[
            Text(
              'Enter OTP',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.secondary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                  color: AppTheme.onSurface),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: '',
                hintText: '------',
                hintStyle: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    letterSpacing: 6,
                    color: AppTheme.secondary.withValues(alpha: 0.4)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: AppTheme.surface,
                border: const UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: AppTheme.surfaceContainerHigh, width: 2)),
                enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: AppTheme.surfaceContainerHigh, width: 2)),
                focusedBorder: const UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFF059669), width: 2)),
              ),
            ),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (_showOTPField ? _verifyOTP : _sendOTP),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _showOTPField ? 'Verify OTP' : 'Send OTP',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05);
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: AppTheme.surfaceContainerHighest),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF94A3B8),
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: AppTheme.surfaceContainerHighest),
        ),
      ],
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildIdPasswordCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusXl,
        border: Border(
          left: BorderSide(color: AppTheme.primaryContainer, width: 3),
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
                const Icon(Icons.key_rounded,
                    color: AppTheme.primaryContainer, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Login with Email & Password',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Error banner
            if (_errorMessage.isNotEmpty && !_showPhonePanel) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                            color: Color(0xFFEF4444), fontSize: 13),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.secondary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 14, color: AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: 'admin@tableos.in',
                hintStyle: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    color: AppTheme.secondary.withValues(alpha: 0.5)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: AppTheme.surface,
                border: const UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: AppTheme.surfaceContainerHigh, width: 2)),
                enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: AppTheme.surfaceContainerHigh, width: 2)),
                focusedBorder: const UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: AppTheme.primaryContainer, width: 2)),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter email';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Password',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.secondary),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryContainer,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: GoogleFonts.inter(
                    color: AppTheme.secondary.withValues(alpha: 0.5)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: AppTheme.surface,
                border: const UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: AppTheme.surfaceContainerHigh, width: 2)),
                enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: AppTheme.surfaceContainerHigh, width: 2)),
                focusedBorder: const UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: AppTheme.primaryContainer, width: 2)),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppTheme.secondary,
                    size: 20,
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
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loginWithPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  shadowColor: AppTheme.primary.withValues(alpha: 0.3),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
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
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.login_rounded, size: 18),
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
        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.secondary),
        children: [
          const TextSpan(text: 'Having trouble? '),
          TextSpan(
            text: 'Contact Support',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryContainer,
              decoration: TextDecoration.underline,
              decorationColor:
                  AppTheme.primaryContainer.withValues(alpha: 0.4),
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
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
