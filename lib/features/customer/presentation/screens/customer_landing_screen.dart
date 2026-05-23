// lib/features/customer/presentation/screens/customer_landing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../menu/presentation/state/menu_providers.dart';
import '../state/customer_providers.dart';
import '../widgets/customer_components.dart';

class CustomerLandingScreen extends ConsumerStatefulWidget {
  final String? tenantId;
  final String? branchId;
  final String? tableId;

  const CustomerLandingScreen({
    super.key,
    this.tenantId,
    this.branchId,
    this.tableId,
  });

  @override
  ConsumerState<CustomerLandingScreen> createState() => _CustomerLandingScreenState();
}

class _CustomerLandingScreenState extends ConsumerState<CustomerLandingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _validateAndInit();
  }

  void _validateAndInit() {
    if (widget.tenantId == null || widget.branchId == null || widget.tableId == null) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Invalid QR code. Please check and scan again.';
      });
    } else {
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1E1005), AppColors.darkBackground]
                : [const Color(0xFFFFF0E6), AppColors.lightBackground],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _hasError ? _buildErrorState(theme, isDark) : _buildLandingState(theme, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildLandingState(ThemeData theme, bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decorative Brand Logo/Icon
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 4),
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome to Orderlyy',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.info,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Ready to explore the menu and place your order?',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            // Seating context card
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.table_restaurant_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Seated at Table ${widget.tableId}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // Start Ordering Button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'View Menu & Order',
                icon: Icons.qr_code_scanner_rounded,
                onPressed: () {
                  // Initialize Customer Session
                  ref.read(customerSessionProvider.notifier).initializeSession(
                        widget.tenantId!,
                        widget.branchId!,
                        widget.tableId!,
                      );
                  // Pre-fetch/refresh menu snapshot for customer branch
                  ref.read(menuSnapshotNotifierProvider.notifier).loadMenu();
                  // Route to Menu screen
                  context.push('/customer/menu');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'Session Initialization Failed',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          Semantics(
            label: 'Retry Scan button',
            button: true,
            child: SizedBox(
              width: 180,
              child: AppButton(
                label: 'Close',
                onPressed: () {
                  context.go('/splash');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
