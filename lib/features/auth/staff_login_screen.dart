import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/auth_provider.dart';
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

  // ── Verify tenant slug with Supabase ──────────────────────────────────────
  Future<void> _verifyTenantSlug(String slug) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final response = await Supabase.instance.client
          .from('tenants')
          .select('id, name, slug')
          .eq('slug', slug)
          .eq('status', 'active')
          .maybeSingle();

      if (response == null) {
        setState(() {
          _errorMessage = 'Restaurant not found. Check the code.';
          _scannerActive = true;
        });
        return;
      }

      setState(() {
        _tenantSlug = response['slug'] as String;
        _tenantName = response['name'] as String;
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

  // ── Submit PIN ─────────────────────────────────────────────────────────────
  Future<void> _submitPin() async {
    final pin = _pin.join();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = ref.read(authServiceProvider);
      final staff = await authService.staffPinLogin(_tenantSlug, pin);

      if (staff == null) {
        setState(() {
          _pin.clear();
          _errorMessage = 'Invalid PIN. Try again.';
        });
        return;
      }

      // Store staff session
      ref.read(staffSessionProvider.notifier).setStaff(staff);

      // Persist restaurant for "remember me"
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tenant_slug', _tenantSlug);
      await prefs.setString('tenant_name', _tenantName);

      // Navigate by role
      final role = staff['role'] as String;
      if (!mounted) return;
      if (role == 'waiter') {
        context.go('/staff/tables');
      } else if (role == 'manager') {
        context.go('/manager/dashboard');
      } else if (role == 'owner') {
        context.go('/admin/dashboard');
      } else {
        context.go('/staff/tables');
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.secondary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Staff Login',
          style: GoogleFonts.inter(
            fontSize: 18,
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
              indicatorWeight: 2,
              labelColor: AppTheme.primaryContainer,
              unselectedLabelColor: AppTheme.secondary,
              labelStyle:
                  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle:
                  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
              dividerColor: AppTheme.surfaceContainerHighest,
              tabs: const [
                Tab(
                  icon: Icon(Icons.qr_code_scanner_rounded, size: 18),
                  text: 'Scan QR',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
                Tab(
                  icon: Icon(Icons.keyboard_rounded, size: 18),
                  text: 'Enter Code',
                  iconMargin: EdgeInsets.only(bottom: 4),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildScanTab(),
                _buildCodeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (!_restaurantConfirmed) ...[
          // ── Camera viewfinder ────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  MobileScanner(onDetect: _onQrDetected),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(64),
                      child: _QrBrackets(),
                    ),
                  ),
                  Positioned(
                    top: 0, bottom: 0, left: 0, right: 0,
                    child: Center(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer
                              .withValues(alpha: 0.4),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.6),
                              blurRadius: 15,
                              spreadRadius: 2,
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
          const SizedBox(height: 16),
          Text(
            'Point camera at restaurant QR code',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.secondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],

        if (_isLoading && !_restaurantConfirmed)
          const Center(child: CircularProgressIndicator()),

        if (_errorMessage.isNotEmpty) _buildErrorBanner(),

        if (_restaurantConfirmed) ...[
          _buildRestaurantConfirmedCard(),
          const SizedBox(height: 24),
          _buildPinSection(),
        ],
      ],
    );
  }

  Widget _buildCodeTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (!_restaurantConfirmed) ...[
          Text(
            'Enter Restaurant Code',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Ask your admin for the restaurant code',
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.secondary),
          ),
          const SizedBox(height: 24),

          if (_errorMessage.isNotEmpty) ...[
            _buildErrorBanner(),
            const SizedBox(height: 16),
          ],

          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.text,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: AppTheme.onSurface),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'my-restaurant',
              hintStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 18,
                  letterSpacing: 2,
                  color: AppTheme.secondary.withValues(alpha: 0.4)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppTheme.surfaceContainerHigh, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppTheme.surfaceContainerHigh, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppTheme.primaryContainer, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _verifyTenantSlug(_codeController.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Confirm Restaurant',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],

        if (_restaurantConfirmed) ...[
          _buildRestaurantConfirmedCard(),
          const SizedBox(height: 24),
          _buildPinSection(),
        ],
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style:
                  const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantConfirmedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        border: const Border(
          left: BorderSide(color: Color(0xFF10B981), width: 4),
        ),
        boxShadow: AppTheme.crimsonShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF10B981), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tenantName,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface),
                ),
                Text(
                  'Slug: $_tenantSlug',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.secondary,
                      letterSpacing: 0.5),
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
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
              letterSpacing: -0.3),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 4),
        Text(
          '4-digit PIN given by your admin',
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.secondary),
        ),
        const SizedBox(height: 28),

        // Error
        if (_errorMessage.isNotEmpty) ...[
          _buildErrorBanner(),
          const SizedBox(height: 16),
        ],

        // PIN dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_pinLength, (i) {
            final filled = i < _pin.length;
            return Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? AppTheme.primary
                    : AppTheme.surfaceContainerHighest,
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
            );
          }),
        ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
        const SizedBox(height: 36),

        // Keypad
        _isLoading
            ? const CircularProgressIndicator()
            : SizedBox(
                width: 280,
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: [
                    ...[
                      '1', '2', '3',
                      '4', '5', '6',
                      '7', '8', '9',
                    ].map((n) =>
                        _KeypadButton(label: n, onTap: () => _onKeypadTap(n))),
                    const SizedBox(),
                    _KeypadButton(
                        label: '0', onTap: () => _onKeypadTap('0')),
                    _KeypadButton(
                      icon: Icons.backspace_rounded,
                      isBackspace: true,
                      onTap: () => _onKeypadTap('backspace'),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 150.ms),

        const SizedBox(height: 24),
        TextButton(
          onPressed: _startOver,
          child: Text(
            'Wrong restaurant? Start over',
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryContainer),
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
    const bracketSize = 48.0;
    const strokeWidth = 4.0;
    const color = AppTheme.primaryContainer;
    const radius = Radius.circular(8);

    return Stack(
      children: [
        Positioned(
          top: 0, left: 0,
          child: Container(
            width: bracketSize, height: bracketSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: strokeWidth),
                left: BorderSide(color: color, width: strokeWidth),
              ),
              borderRadius: BorderRadius.only(topLeft: radius),
            ),
          ),
        ),
        Positioned(
          top: 0, right: 0,
          child: Container(
            width: bracketSize, height: bracketSize,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: color, width: strokeWidth),
                right: BorderSide(color: color, width: strokeWidth),
              ),
              borderRadius: BorderRadius.only(topRight: radius),
            ),
          ),
        ),
        Positioned(
          bottom: 0, left: 0,
          child: Container(
            width: bracketSize, height: bracketSize,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: strokeWidth),
                left: BorderSide(color: color, width: strokeWidth),
              ),
              borderRadius: BorderRadius.only(bottomLeft: radius),
            ),
          ),
        ),
        Positioned(
          bottom: 0, right: 0,
          child: Container(
            width: bracketSize, height: bracketSize,
            decoration: const BoxDecoration(
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
        width: 72,
        height: 72,
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
              ? Icon(widget.icon, color: AppTheme.primary, size: 26)
              : Text(
                  widget.label!,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
        ),
      ),
    );
  }
}
