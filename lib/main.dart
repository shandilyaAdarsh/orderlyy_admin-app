import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/network/secure_storage.dart';
import 'core/network/network_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/data/mock/mock_auth_repository.dart';
import 'core/providers/repository_providers.dart';
import 'core/storage/local_storage.dart';
import 'core/storage/hive_storage.dart';

// ── Mock mode: Supabase.initialize() is intentionally removed. ────────────────
// The app is fully decoupled from the backend during this phase.
// See: core/providers/repository_providers.dart for wiring.
// See: core/data/mock/ for all mock implementations.
// Toggle `kUseMockRepositories` in repository_providers.dart when ready.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Hive Database Snapshot Cache
  await HiveStorage.initialize();
  final apiCacheBox = await Hive.openBox<String>('api_cache');
  final offlineQueueBox = await Hive.openBox<String>('offline_writes');

  // Initialize App Configuration
  AppConfig.initialize();

  final prefs = await SharedPreferences.getInstance();

  // Initialize local storage
  final localStorage = SharedPreferencesStorage(prefs);

  // ── Restore persisted mock session before the widget tree builds ──────────
  // This ensures currentUserIdProvider has the correct value on first frame,
  // preventing the splash → role-select flash for returning users.
  if (kUseMockRepositories) {
    debugPrint('[Main] 🔄 Force sign out to start from login page...');
    final mockRepo = MockAuthRepository();
    debugPrint('[AUTH INSTANCE] [Main] mockRepo.hashCode=${mockRepo.hashCode}');
    await mockRepo.signOut();
    // Override the providers with pre-seeded instances
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          authRepositoryProvider.overrideWithValue(mockRepo),
          apiCacheBoxProvider.overrideWithValue(apiCacheBox),
          offlineQueueBoxProvider.overrideWithValue(offlineQueueBox),
        ],
        child: const OrderlliApp(),
      ),
    );
    return;
  }

  // Supabase initialization with Secure Token Storage
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://placeholder.supabase.co');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'placeholder-key');
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureLocalStorage(),
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageProvider.overrideWithValue(localStorage),
        apiCacheBoxProvider.overrideWithValue(apiCacheBox),
        offlineQueueBoxProvider.overrideWithValue(offlineQueueBox),
      ],
      child: const OrderlliApp(),
    ),
  );
}

class OrderlliApp extends ConsumerWidget {
  const OrderlliApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
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
