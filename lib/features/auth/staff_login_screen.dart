import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/auth/mock_auth_provider.dart';
import '../../core/data/dtos/auth_dto.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_theme.dart';

class StaffLoginScreen extends ConsumerStatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  ConsumerState<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends ConsumerState<StaffLoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Restaurant state
  String _tenantSlug = '';
  String _tenantName = '';
  bool _restaurantConfirmed = false;
  bool _scannerActive = true;

  // Code entry
  final _codeController = TextEditingController();

  // PIN state
  final List<String> _pin = [];
  static const int _pinLength = 4;

  // Loading / error
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
    });
    _loadSavedRestaurant();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // ── Load saved restaurant from SharedPreferences ───────────────────────────
  Future<void> _loadSavedRestaurant() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSlug = prefs.getString('tenant_slug');
    final savedName = prefs.getString('tenant_name');
    if (savedSlug != null && savedName != null) {
      setState(() {
        _tenantSlug = savedSlug;
        _tenantName = savedName;
        _restaurantConfirmed = true;
      });
    }
  }

  // ── QR code detected ──────────────────────────────────────────────────────
  void _onQrDetected(BarcodeCapture capture) {
    if (!_scannerActive || _restaurantConfirmed) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    final code = barcode!.rawValue!;
    setState(() => _scannerActive = false);
    _verifyTenantSlug(code);
  }

  // ── Verify tenant slug (mock) ────────────────────────────────────────────
  Future<void> _verifyTenantSlug(String slug) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      if (slug.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please enter a restaurant code.';
          _scannerActive = true;
        });
        return;
      }
      // Mock: 'spice-garden' is the demo tenant. Any other slug is accepted too.
      final mockName = slug == 'spice-garden'
          ? 'The Spice Garden'
          : slug
                .split('-')
                .map(
                  (w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1),
                )
                .join(' ');
      setState(() {
        _tenantSlug = slug.trim();
        _tenantName = mockName;
        _restaurantConfirmed = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error verifying restaurant.';
        _scannerActive = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Keypad tap handler ────────────────────────────────────────────────────
  void _onKeypadTap(String key) {
    if (_isLoading) return;
    if (key == 'backspace') {
      if (_pin.isNotEmpty) setState(() => _pin.removeLast());
    } else if (_pin.length < _pinLength) {
      setState(() => _pin.add(key));
      if (_pin.length == _pinLength) {
        Future.delayed(const Duration(milliseconds: 300), _submitPin);
      }
    }
  }

  // ── Submit PIN (via AuthRepository — backend-agnostic) ───────────────────
  Future<void> _submitPin() async {
    final pin = _pin.join();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final response = await authRepo.staffPinLogin(
        StaffPinLoginRequestDto(tenantSlug: _tenantSlug, pin: pin),
      );

      if (!response.isSuccess || response.staff == null) {
        setState(() {
          _pin.clear();
          _errorMessage = response.errorMessage ?? 'Invalid PIN. Try again.';
        });
        return;
      }

      final staff = response.staff!;

      // Store staff session in Riverpod
      ref.read(staffSessionProvider.notifier).setStaff(staff);

      // Persist restaurant slug for next launch
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tenant_slug', _tenantSlug);
      await prefs.setString('tenant_name', _tenantName);

      // Navigate by role
      if (!mounted) return;
      switch (staff.role) {
        case 'waiter':
          context.go('/staff/tables');
        case 'manager':
          context.go('/manager/dashboard');
        case 'owner':
        default:
          context.go('/admin/dashboard');
      }
    } catch (e) {
      setState(() {
        _pin.clear();
        _errorMessage = 'Login failed. Try again.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Start over / clear restaurant ─────────────────────────────────────────
  Future<void> _startOver() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tenant_slug');
    await prefs.remove('tenant_name');
    setState(() {
      _tenantSlug = '';
      _tenantName = '';
      _restaurantConfirmed = false;
      _pin.clear();
      _errorMessage = '';
      _scannerActive = true;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        toolbarHeight: 64.h,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.secondary,
            size: 24.r,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Staff Login',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Tabs ────────────────────────────────────────────────────────────
          Container(
            color: AppTheme.surfaceContainerLowest,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryContainer,
              indicatorWeight: 2.h,
              labelColor: AppTheme.primaryContainer,
              unselectedLabelColor: AppTheme.secondary,
              labelStyle: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              dividerColor: AppTheme.surfaceContainerHighest,
              tabs: [
                Tab(
                  icon: Icon(Icons.qr_code_scanner_rounded, size: 18.r),
                  text: 'Scan QR',
                  iconMargin: EdgeInsets.only(bottom: 4.h),
                ),
                Tab(
                  icon: Icon(Icons.keyboard_rounded, size: 18.r),
                  text: 'Enter Code',
                  iconMargin: EdgeInsets.only(bottom: 4.h),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildScanTab(), _buildCodeTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    return ListView(
      padding: EdgeInsets.all(24.r),
      children: [
        if (!_restaurantConfirmed) ...[
          // ── Camera viewfinder ────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  MobileScanner(onDetect: _onQrDetected),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(64.r),
                      child: _QrBrackets(),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        height: 2.h,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer.withValues(
                            alpha: 0.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.6),
                              blurRadius: 15.r,
                              spreadRadius: 2.r,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),
          SizedBox(height: 16.h),
          Text(
            'Point camera at restaurant QR code',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
        ],

        if (_isLoading && !_restaurantConfirmed)
          const Center(child: CircularProgressIndicator()),

        if (_errorMessage.isNotEmpty) _buildErrorBanner(),

        if (_restaurantConfirmed) ...[
          _buildRestaurantConfirmedCard(),
          SizedBox(height: 24.h),
          _buildPinSection(),
        ],
      ],
    );
  }

  Widget _buildCodeTab() {
    return ListView(
      padding: EdgeInsets.all(24.r),
      children: [
        if (!_restaurantConfirmed) ...[
          Text(
            'Enter Restaurant Code',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ).animate().fadeIn(duration: 400.ms),
          SizedBox(height: 8.h),
          Text(
            'Ask your admin for the restaurant code',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: AppTheme.secondary,
            ),
          ),
          SizedBox(height: 24.h),

          if (_errorMessage.isNotEmpty) ...[
            _buildErrorBanner(),
            SizedBox(height: 16.h),
          ],

          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.text,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: AppTheme.onSurface,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'my-restaurant',
              hintStyle: GoogleFonts.jetBrainsMono(
                fontSize: 18.sp,
                letterSpacing: 2,
                color: AppTheme.secondary.withValues(alpha: 0.4),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 18.h,
              ),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: AppTheme.surfaceContainerHigh,
                  width: 2.w,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: AppTheme.surfaceContainerHigh,
                  width: 2.w,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: AppTheme.primaryContainer,
                  width: 2.w,
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 52.h,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _verifyTenantSlug(_codeController.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20.r,
                      width: 20.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Confirm Restaurant',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],

        if (_restaurantConfirmed) ...[
          _buildRestaurantConfirmedCard(),
          SizedBox(height: 24.h),
          _buildPinSection(),
        ],
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
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
          Icon(Icons.error_outline, color: const Color(0xFFEF4444), size: 16.r),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(color: const Color(0xFFEF4444), fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantConfirmedCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        border: Border(
          left: BorderSide(color: const Color(0xFF10B981), width: 4.w),
        ),
        boxShadow: AppTheme.crimsonShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              size: 22.r,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tenantName,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Slug: $_tenantSlug',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.secondary,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildPinSection() {
    return Column(
      children: [
        Text(
          'Enter your PIN',
          style: GoogleFonts.inter(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
            letterSpacing: -0.3,
          ),
        ).animate().fadeIn(duration: 300.ms),
        SizedBox(height: 4.h),
        Text(
          '4-digit PIN given by your admin',
          style: GoogleFonts.inter(fontSize: 14.sp, color: AppTheme.secondary),
        ),
        SizedBox(height: 28.h),

        // Error
        if (_errorMessage.isNotEmpty) ...[
          _buildErrorBanner(),
          SizedBox(height: 16.h),
        ],

        // PIN dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_pinLength, (i) {
            final filled = i < _pin.length;
            return Container(
              width: 16.r,
              height: 16.r,
              margin: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? AppTheme.primary
                    : AppTheme.surfaceContainerHighest,
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8.r,
                          spreadRadius: 2.r,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
        SizedBox(height: 36.h),

        // Keypad
        _isLoading
            ? const CircularProgressIndicator()
            : SizedBox(
                width: 280.w,
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 20.h,
                  crossAxisSpacing: 20.w,
                  children: [
                    ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map(
                      (n) =>
                          _KeypadButton(label: n, onTap: () => _onKeypadTap(n)),
                    ),
                    const SizedBox(),
                    _KeypadButton(label: '0', onTap: () => _onKeypadTap('0')),
                    _KeypadButton(
                      icon: Icons.backspace_rounded,
                      isBackspace: true,
                      onTap: () => _onKeypadTap('backspace'),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 150.ms),

        SizedBox(height: 24.h),
        TextButton(
          onPressed: _startOver,
          child: Text(
            'Wrong restaurant? Start over',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryContainer,
            ),
          ),
        ),
      ],
    );
  }
}

// ── QR Corner Brackets ────────────────────────────────────────────────────────
class _QrBrackets extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bracketSize = 48.r;
    final strokeWidth = 4.w;
    const color = AppTheme.primaryContainer;
    final radius = Radius.circular(8.r);

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: bracketSize,
            height: bracketSize,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: strokeWidth),
                left: BorderSide(color: color, width: strokeWidth),
              ),
              borderRadius: BorderRadius.only(topLeft: radius),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: bracketSize,
            height: bracketSize,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: strokeWidth),
                right: BorderSide(color: color, width: strokeWidth),
              ),
              borderRadius: BorderRadius.only(topRight: radius),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: bracketSize,
            height: bracketSize,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: strokeWidth),
                left: BorderSide(color: color, width: strokeWidth),
              ),
              borderRadius: BorderRadius.only(bottomLeft: radius),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: bracketSize,
            height: bracketSize,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: strokeWidth),
                right: BorderSide(color: color, width: strokeWidth),
              ),
              borderRadius: BorderRadius.only(bottomRight: radius),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Keypad Button ─────────────────────────────────────────────────────────────
class _KeypadButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final bool isBackspace;
  final VoidCallback onTap;

  const _KeypadButton({
    this.label,
    this.icon,
    this.isBackspace = false,
    required this.onTap,
  });

  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton> {
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 72.r,
        height: 72.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isBackspace
              ? (_pressed
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : AppTheme.primary.withValues(alpha: 0.1))
              : (_pressed
                    ? AppTheme.surfaceContainerHigh
                    : AppTheme.surfaceContainerLow),
        ),
        child: Center(
          child: widget.icon != null
              ? Icon(widget.icon, color: AppTheme.primary, size: 26.r)
              : Text(
                  widget.label!,
                  style: GoogleFonts.inter(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
        ),
      ),
    );
  }
}
