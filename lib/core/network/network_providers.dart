import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';
import '../providers/repository_providers.dart';
import 'dio_client.dart';

/// Provider for the global structured Dio HTTP Client
final dioClientProvider = Provider<DioClient>((ref) {
  final talker = ref.watch(talkerProvider);
  
  return DioClient(
    talker: talker,
    onUnauthorized: () {
      logWarning('[DioClient] 🚨 Unauthorized request (401) detected. Signing out...');
      ref.read(authRepositoryProvider).signOut();
    },
  );
});
