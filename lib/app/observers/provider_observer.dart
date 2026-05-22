// lib/app/observers/provider_observer.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppProviderObserver extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      print('[Provider Added] ${provider.name ?? provider.runtimeType} initialized.');
    }
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      print('[Provider Updated] ${provider.name ?? provider.runtimeType} updated state.');
    }
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      print('[Provider Disposed] ${provider.name ?? provider.runtimeType} disposed.');
    }
  }
}
