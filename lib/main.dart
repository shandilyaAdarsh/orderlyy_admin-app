import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: OrderlliApp()));
}

class OrderlliApp extends ConsumerWidget {
  const OrderlliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

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

