// lib/features/realtime/domain/entities/realtime_state_model.dart

enum RealtimeConnectionState {
  connected,
  reconnecting,
  replaying,
  degraded,
  critical,
}

class RealtimeStateModel {
  final RealtimeConnectionState connectionState;
  final int reconnectAttempts;
  final int maxReconnectAttempts;
  final double? replayProgress; // 0.0–1.0, null if not replaying
  final int? replayEventsRemaining;
  final DateTime? lastConnectedAt;
  final DateTime? degradedSince;
  final String? errorMessage;

  const RealtimeStateModel({
    required this.connectionState,
    this.reconnectAttempts = 0,
    this.maxReconnectAttempts = 5,
    this.replayProgress,
    this.replayEventsRemaining,
    this.lastConnectedAt,
    this.degradedSince,
    this.errorMessage,
  });

  RealtimeStateModel copyWith({
    RealtimeConnectionState? connectionState,
    int? reconnectAttempts,
    int? maxReconnectAttempts,
    double? replayProgress,
    int? replayEventsRemaining,
    DateTime? lastConnectedAt,
    DateTime? degradedSince,
    String? errorMessage,
    bool clearReplayProgress = false,
    bool clearReplayEventsRemaining = false,
    bool clearDegradedSince = false,
    bool clearErrorMessage = false,
  }) {
    return RealtimeStateModel(
      connectionState: connectionState ?? this.connectionState,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      maxReconnectAttempts: maxReconnectAttempts ?? this.maxReconnectAttempts,
      replayProgress: clearReplayProgress ? null : replayProgress ?? this.replayProgress,
      replayEventsRemaining: clearReplayEventsRemaining
          ? null
          : replayEventsRemaining ?? this.replayEventsRemaining,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      degradedSince: clearDegradedSince ? null : degradedSince ?? this.degradedSince,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  bool get isHealthy => connectionState == RealtimeConnectionState.connected;
  bool get isCritical => connectionState == RealtimeConnectionState.critical;
  bool get isReplaying => connectionState == RealtimeConnectionState.replaying;
  bool get isDegraded => connectionState == RealtimeConnectionState.degraded;
  bool get isReconnecting => connectionState == RealtimeConnectionState.reconnecting;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RealtimeStateModel &&
        other.connectionState == connectionState &&
        other.reconnectAttempts == reconnectAttempts &&
        other.maxReconnectAttempts == maxReconnectAttempts &&
        other.replayProgress == replayProgress &&
        other.replayEventsRemaining == replayEventsRemaining &&
        other.lastConnectedAt == lastConnectedAt &&
        other.degradedSince == degradedSince &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
        connectionState,
        reconnectAttempts,
        maxReconnectAttempts,
        replayProgress,
        replayEventsRemaining,
        lastConnectedAt,
        degradedSince,
        errorMessage,
      );

  @override
  String toString() =>
      'RealtimeStateModel(connectionState: $connectionState, '
      'reconnectAttempts: $reconnectAttempts/$maxReconnectAttempts, '
      'replayProgress: $replayProgress, errorMessage: $errorMessage)';
}
