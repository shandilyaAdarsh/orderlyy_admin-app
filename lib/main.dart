import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

// ── Mock mode: Supabase.initialize() is intentionally removed. ────────────────
// The app is fully decoupled from the backend during this phase.
// See: core/providers/repository_providers.dart for wiring.
// See: core/data/mock/ for all mock implementations.
// Toggle `kUseMockRepositories` in repository_providers.dart when ready.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NOTE: Supabase.initialize() is intentionally skipped in mock mode.
  // Restore it when kUseMockRepositories = false.

  runApp(const ProviderScope(child: OrderlliApp()));
}

class OrderlliApp extends ConsumerWidget {
  const OrderlliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isDesktop = !kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    return ScreenUtilInit(
      designSize: isDesktop ? const Size(1280, 800) : const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp.router(
        title: 'Orderlli',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
