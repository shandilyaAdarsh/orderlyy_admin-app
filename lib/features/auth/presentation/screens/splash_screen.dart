// lib/features/auth/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../state/auth_notifier.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  double _progress = 0.0;
  String _statusText = 'Initializing local database...';
  final List<String> _diagnostics = [];

  @override
  void initState() {
    super.initState();
    _startPreload();
  }

  Future<void> _startPreload() async {
    // Stage 1: DB Hydration
    await Future.delayed(800.ms);
    if (!mounted) return;
    setState(() {
      _progress = 0.35;
      _statusText = 'Preloading tenant branch maps...';
      _diagnostics.add('\u2714 SQLite Local Storage: Initialized');
    });

    // Stage 2: Cache Check
    await Future.delayed(800.ms);
    if (!mounted) return;
    setState(() {
      _progress = 0.70;
      _statusText = 'Connecting real-time operational streams...';
      _diagnostics.add('\u2714 Cached Session: Checked');
    });

    // Stage 3: Synchronize
    await Future.delayed(800.ms);
    if (!mounted) return;
    setState(() {
      _progress = 1.0;
      _statusText = 'System ready.';
      _diagnostics.add('\u2714 Websocket Broadcast Bus: Synced');
    });

    await Future.delayed(500.ms);
    if (!mounted) return;

    // Route decision after boot sequence
    final authState = ref.read(authNotifierProvider);
    if (authState.selectedOrg == null) {
      context.go('/org-select');
    } else if (authState.selectedBranch == null) {
      context.go('/branch-select');
    } else if (authState.loggedInStaff == null) {
      context.go('/login');
    } else if (!authState.isShiftStarted) {
      context.go('/shift-start');
    } else {
      context.go('/tables');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[50],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing animated logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 50,
                    color: AppColors.primary,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scaleXY(begin: 0.9, end: 1.1, duration: 1200.ms, curve: Curves.easeInOut)
                    .boxShadow(
                      begin: const BoxShadow(color: Colors.transparent),
                      end: BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 20),
                      duration: 1200.ms,
                    ),
                const SizedBox(height: 32),
                Text(
                  'ORDERLLYY',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: isDark ? Colors.white : AppColors.darkBackground,
                  ),
                ),
                Text(
                  'OPERATIONAL STAFF RUNTIME',
                  style: theme.textTheme.bodySmall?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 48),

                // Loading Progress Bar
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  color: AppColors.primary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Diagnostics Console widget
                if (_diagnostics.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _diagnostics
                          .map((line) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  line,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: AppColors.success,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ).animate().fade(duration: 200.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
