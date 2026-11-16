import 'package:flutter/foundation.dart';
import 'environment.dart';

class AppConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String websocketUrl;
  final String customerAppUrl;
  final bool enableLogging;
  final bool enableSentry;
  final Map<String, bool> featureFlags;

  static late AppConfig _instance;
  static AppConfig get instance => _instance;

  static const bool isPilotMode = true; // flip to false for full access

  AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.websocketUrl,
    required this.customerAppUrl,
    required this.enableLogging,
    required this.enableSentry,
    required this.featureFlags,
  });

  static void initialize({
    Environment? environment,
    String? apiBaseUrl,
    String? websocketUrl,
    String? customerAppUrl,
    bool? enableLogging,
    bool? enableSentry,
    Map<String, bool>? featureFlags,
  }) {
    // Read from --dart-define or fallback
    const envString = String.fromEnvironment('ENV', defaultValue: '');
    final resolvedEnv = environment ?? (kReleaseMode ? Environment.prod : _parseEnvironment(envString));

    const rawApiUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    const rawWsUrl = String.fromEnvironment('WEBSOCKET_URL', defaultValue: '');
    const rawCustomerUrl = String.fromEnvironment('CUSTOMER_APP_URL', defaultValue: '');

    String resolvedApiUrl = (apiBaseUrl ?? rawApiUrl).trim();
    if (resolvedApiUrl.isEmpty) {
      if (resolvedEnv == Environment.prod || kReleaseMode) {
        resolvedApiUrl = 'https://table-os.onrender.com';
      } else {
        resolvedApiUrl = _resolvePlatformLocalhost('http://localhost:3001', resolvedEnv);
      }
    }
    resolvedApiUrl = resolvedApiUrl.replaceAll(RegExp(r'/+$'), '');
    if (resolvedApiUrl.endsWith('/api/v1')) {
      resolvedApiUrl = resolvedApiUrl.substring(0, resolvedApiUrl.length - 7);
    }

    String resolvedCustomerUrl = (customerAppUrl ?? rawCustomerUrl).trim();
    if (resolvedCustomerUrl.isEmpty) {
      if (resolvedEnv == Environment.prod || kReleaseMode) {
        resolvedCustomerUrl = 'https://table-os-1.onrender.com';
      } else {
        // Prevent development builds from silently generating localhost QR codes intended for customers
        debugPrint(
          '[AppConfig] WARNING: CUSTOMER_APP_URL not set via --dart-define. '
          'Defaulting to production customer menu: https://table-os-1.onrender.com. '
          'To test against local Vite, pass --dart-define=CUSTOMER_APP_URL=http://localhost:5173',
        );
        resolvedCustomerUrl = 'https://table-os-1.onrender.com';
      }
    } else {
      if (resolvedEnv == Environment.dev) {
        resolvedCustomerUrl = _resolvePlatformLocalhost(resolvedCustomerUrl, resolvedEnv);
      }
    }
    resolvedCustomerUrl = resolvedCustomerUrl.replaceAll(RegExp(r'/+$'), '');

    if (resolvedCustomerUrl.isEmpty) {
      throw StateError('[AppConfig] CUSTOMER_APP_URL must not be empty.');
    }
    if (!resolvedCustomerUrl.startsWith('http://') && !resolvedCustomerUrl.startsWith('https://')) {
      throw StateError('[AppConfig] CUSTOMER_APP_URL must be a valid HTTP or HTTPS URL. Got: $resolvedCustomerUrl');
    }

    String resolvedWsUrl = (websocketUrl ?? rawWsUrl).trim();
    if (resolvedWsUrl.isEmpty) {
      if (resolvedEnv == Environment.prod || kReleaseMode) {
        resolvedWsUrl = 'wss://table-os.onrender.com/api/v1/realtime';
      } else {
        final uri = Uri.parse(resolvedApiUrl);
        final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
        final portPart = (uri.hasPort && uri.port != 80 && uri.port != 443) ? ':${uri.port}' : '';
        resolvedWsUrl = '$wsScheme://${uri.host}$portPart/api/v1/realtime';
      }
    }

    _instance = AppConfig._(
      environment: resolvedEnv,
      apiBaseUrl: resolvedApiUrl,
      websocketUrl: resolvedWsUrl,
      customerAppUrl: resolvedCustomerUrl,
      enableLogging:
          enableLogging ??
          const bool.fromEnvironment('ENABLE_LOGGING', defaultValue: true),
      enableSentry:
          enableSentry ??
          const bool.fromEnvironment('ENABLE_SENTRY', defaultValue: false),
      featureFlags:
          featureFlags ??
          {
            'useOfflineMode': const bool.fromEnvironment(
              'FLAG_OFFLINE_MODE',
              defaultValue: true,
            ),
            'experimentalKds': const bool.fromEnvironment(
              'FLAG_EXPERIMENTAL_KDS',
              defaultValue: false,
            ),
            'enableExperimentalRealtime': const bool.fromEnvironment(
              'FLAG_EXPERIMENTAL_REALTIME',
              defaultValue: false,
            ),
            'enableExperimentalOcc': const bool.fromEnvironment(
              'FLAG_EXPERIMENTAL_OCC',
              defaultValue: false,
            ),
          },
    );
  }

  static Environment _parseEnvironment(String env) {
    switch (env.toLowerCase()) {
      case 'prod':
      case 'production':
        return Environment.prod;
      case 'staging':
        return Environment.staging;
      case 'dev':
      case 'development':
      default:
        return Environment.dev;
    }
  }

  static String _resolvePlatformLocalhost(String url, Environment env) {
    // Only map local URLs in development.
    if (env != Environment.dev) return url;
    
    if (kIsWeb) return url;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return url.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
    }
    return url;
  }

  /// Centralized builder for all customer menu QR code URLs.
  /// Format: `https://table-os-1.onrender.com/t/<token>`
  String buildCustomerQrUrl(String token) {
    final cleanToken = token.trim();
    assert(cleanToken.isNotEmpty, 'QR token must not be empty');
    return '$customerAppUrl/t/$cleanToken';
  }

  /// Normalizes any existing/persisted QR URL or token to ensure it uses the
  /// current customerAppUrl base URL while strictly preserving the existing token.
  String normalizeCustomerQrUrl(String? rawUrlOrToken, {String? fallbackToken}) {
    if (rawUrlOrToken == null || rawUrlOrToken.trim().isEmpty) {
      if (fallbackToken != null && fallbackToken.trim().isNotEmpty) {
        return buildCustomerQrUrl(fallbackToken.trim());
      }
      return '';
    }
    final trimmed = rawUrlOrToken.trim();
    final match = RegExp(r'/t/([^/?#]+)').firstMatch(trimmed);
    if (match != null) {
      final token = match.group(1)!;
      return buildCustomerQrUrl(token);
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return buildCustomerQrUrl(trimmed);
    }
    try {
      final uri = Uri.parse(trimmed);
      final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
      return '$customerAppUrl$path';
    } catch (_) {
      return trimmed;
    }
  }
}
