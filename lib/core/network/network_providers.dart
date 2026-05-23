import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../utils/logger.dart';
import '../providers/repository_providers.dart';
import 'dio_client.dart';
import 'network_info.dart';
import 'offline_queue.dart';

final apiCacheBoxProvider = Provider<Box<String>>((ref) {
  throw UnimplementedError('apiCacheBoxProvider has not been overridden');
});

final offlineQueueBoxProvider = Provider<Box<String>>((ref) {
  throw UnimplementedError('offlineQueueBoxProvider has not been overridden');
});

final offlineQueueManagerProvider = Provider<OfflineQueueManager>((ref) {
  final queueBox = ref.watch(offlineQueueBoxProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  final talker = ref.watch(talkerProvider);
  return OfflineQueueManager(queueBox, networkInfo, talker);
});

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
