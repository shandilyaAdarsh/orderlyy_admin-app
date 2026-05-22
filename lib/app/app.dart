// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../core/network/realtime_sync_manager.dart';

class OrderlyyApp extends ConsumerWidget {
  const OrderlyyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize Realtime Sync Manager to start receiving updates from admin app
    ref.read(realtimeSyncManagerProvider);

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Orderlyy Restaurant Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
