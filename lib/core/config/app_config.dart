// lib/core/config/app_config.dart
import 'environment.dart';

class AppConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String websocketUrl;
  final bool enableSentry;

  static late AppConfig _instance;
  static AppConfig get instance => _instance;

  AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.websocketUrl,
    required this.enableSentry,
  });

  static void initialize({
    required Environment environment,
    required String apiBaseUrl,
    required String websocketUrl,
    required bool enableSentry,
  }) {
    _instance = AppConfig._(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      websocketUrl: websocketUrl,
      enableSentry: enableSentry,
    );
  }
}
