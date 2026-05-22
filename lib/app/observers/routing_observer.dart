// lib/app/observers/routing_observer.dart
import 'package:flutter/material.dart';

class AppRoutingObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('[Navigation Push] Route changed: ${route.settings.name ?? "unnamed"}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('[Navigation Pop] Back to: ${previousRoute?.settings.name ?? "unnamed"}');
  }
}
