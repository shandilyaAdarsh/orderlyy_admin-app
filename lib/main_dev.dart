// lib/main_dev.dart
import 'bootstrap/bootstrap.dart';
import 'core/config/environment.dart';

void main() async {
  await bootstrap(
    environment: Environment.dev,
    apiBaseUrl: 'https://api-dev.orderlyy.com/v1',
    websocketUrl: 'wss://api-dev.orderlyy.com/v1/realtime',
    enableSentry: false,
  );
}
