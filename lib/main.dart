import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/network/supabase_auth_storage.dart';
import 'core/network/network_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/repository_providers.dart';
import 'core/storage/local_storage.dart';
import 'core/storage/hive_storage.dart';
import 'core/device/device_fingerprint_provider.dart';
import 'core/runtime/runtime_reset_service.dart';

import 'core/constants/supabase_constants.dart';

Future<void> main() async {
  const enableSentry =
      bool.fromEnvironment('ENABLE_SENTRY', defaultValue: false);
  const sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue:
        'https://29f6feb26ecd48ef0b238c9833b9d943@o4512208763420672.ingest.de.sentry.io/4512208776462416',
  );

  if (enableSentry) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 1.0;
      },
      // appRunner ensures WidgetsFlutterBinding.ensureInitialized() and
      // runApp() are both called inside the same Sentry-managed zone,
      // preventing the "Zone mismatch" AssertionError.
      appRunner: _bootstrap,
    );
  } else {
    await _bootstrap();
  }
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Hive Database Snapshot Cache
  await HiveStorage.initialize();
  final apiCacheBox = await Hive.openBox<String>('api_cache');
  final offlineQueueBox = await Hive.openBox<String>('offline_writes');

  // Initialize App Configuration
  AppConfig.initialize();

  final prefs = await SharedPreferences.getInstance();
  final fingerprint = await DeviceFingerprintService.initFingerprint(prefs);

  // Initialize local storage
  final localStorage = SharedPreferencesStorage(prefs);

  // Supabase initialization with Secure Token Storage
  final supabaseEnvUrl = const String.fromEnvironment('SUPABASE_URL');
  final supabaseUrl = supabaseEnvUrl.isNotEmpty
      ? supabaseEnvUrl
      : SupabaseConstants.supabaseUrl;

  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: SupabaseConstants.supabaseAnonKey,
  );

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: createSupabaseLocalStorage(supabaseUrl),
    ),
  );

  // ── PHASE 2: Hard User Validation & Schema Version Check Before Hydration ──────────
  final previousUserId = prefs.getString('bootstrap_last_user_id');
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;

  final storedSchemaVersion = prefs.getInt('runtime_schema_version') ?? 0;
  const currentSchemaVersion = 1;

  final isUserMismatch = previousUserId != null &&
      currentUserId != null &&
      previousUserId != currentUserId;
  final isSchemaMismatch = storedSchemaVersion != currentSchemaVersion;

  if (isUserMismatch || isSchemaMismatch) {
    debugPrint(
        '[Main] ⚠️ Runtime reset trigger detected (userMismatch: $isUserMismatch, schemaMismatch: $isSchemaMismatch). Performing hard reset.');
    await RuntimeResetService.fullReset();

    // Save current schema version after reset to prevent loop
    await prefs.setInt('runtime_schema_version', currentSchemaVersion);
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageProvider.overrideWithValue(localStorage),
        apiCacheBoxProvider.overrideWithValue(apiCacheBox),
        offlineQueueBoxProvider.overrideWithValue(offlineQueueBox),
        deviceFingerprintProvider.overrideWithValue(fingerprint),
      ],
      child: const OrderlyyApp(),
    ),
  );
}

class OrderlyyApp extends ConsumerWidget {
  const OrderlyyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp.router(
        title: 'Orderlyy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
