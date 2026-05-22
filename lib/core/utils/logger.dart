// lib/core/utils/logger.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

final talkerProvider = Provider<Talker>((ref) {
  return TalkerFlutter.init(
    settings: TalkerSettings(
      maxHistoryItems: 100,
      useConsoleLogs: true,
    ),
  );
});
