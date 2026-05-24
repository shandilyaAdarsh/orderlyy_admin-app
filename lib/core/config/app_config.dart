import 'environment.dart';

class AppConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String websocketUrl;
  final bool enableLogging;
  final bool enableSentry;
  final Map<String, bool> featureFlags;

  static late AppConfig _instance;
  static AppConfig get instance => _instance;

  AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.websocketUrl,
    required this.enableLogging,
    required this.enableSentry,
    required this.featureFlags,
  });

  static void initialize({
    Environment? environment,
    String? apiBaseUrl,
    String? websocketUrl,
    bool? enableLogging,
    bool? enableSentry,
    Map<String, bool>? featureFlags,
  }) {
    // Read from --dart-define or fallback
    const envString = String.fromEnvironment('ENV', defaultValue: 'dev');
    final resolvedEnv = environment ?? _parseEnvironment(envString);

    _instance = AppConfig._(
      environment: resolvedEnv,
      apiBaseUrl: apiBaseUrl ?? const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.staging.orderlli.com/v1',
      ),
      websocketUrl: websocketUrl ?? const String.fromEnvironment(
        'WEBSOCKET_URL',
        defaultValue: 'wss://api.staging.orderlli.com/v1/ws',
      ),
      enableLogging: enableLogging ?? const bool.fromEnvironment(
        'ENABLE_LOGGING',
        defaultValue: true,
      ),
      enableSentry: enableSentry ?? const bool.fromEnvironment(
        'ENABLE_SENTRY',
        defaultValue: false,
      ),
      featureFlags: featureFlags ?? {
        'useOfflineMode': const bool.fromEnvironment('FLAG_OFFLINE_MODE', defaultValue: true),
        'experimentalKds': const bool.fromEnvironment('FLAG_EXPERIMENTAL_KDS', defaultValue: false),
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
}
