import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/mock_auth_provider.dart';

final runtimeReadyProvider = Provider<bool>((ref) {
  final auth = ref.watch(authNotifierProvider);
  if (auth.status == AuthStatus.loading) {
    return false;
  }
  if (auth.status == AuthStatus.unauthenticated) {
    return true;
  }
  final ctx = ref.watch(appContextProvider);
  return ctx != null;
});
