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

// Global logging helper functions
void logInfo(String message) {
  // Talker can also be used as a static singleton if initialized, 
  // but for convenience within the app we can log via Talker or print in release.
  TalkerFlutter.init().info(message);
}

void logWarning(String message) {
  TalkerFlutter.init().warning(message);
}

void logError(String message, [dynamic error, StackTrace? stackTrace]) {
  TalkerFlutter.init().handle(error ?? message, stackTrace, message);
}

void logDebug(String message) {
  TalkerFlutter.init().debug(message);
}
