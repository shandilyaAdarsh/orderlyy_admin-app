// lib/core/diagnostics/runtime_diagnostics.dart
import 'package:talker_flutter/talker_flutter.dart';

class RuntimeDiagnostics {
  final Talker _talker;

  // Metrics
  int _replayGaps = 0;
  int _rebuildCounts = 0;
  int _replayFailures = 0;
  int _occConflicts = 0;
  int _reconnectStorms = 0;

  RuntimeDiagnostics(this._talker);

  void recordReplayGap() {
    _replayGaps++;
    _talker.warning('[Diagnostics] Replay Gap detected (Total: $_replayGaps)');
  }

  void recordRebuild() {
    _rebuildCounts++;
    _talker.warning('[Diagnostics] Projection Rebuild triggered (Total: $_rebuildCounts)');
  }

  void recordOccConflict() {
    _occConflicts++;
    _talker.warning('[Diagnostics] OCC Conflict occurred (Total: $_occConflicts)');
  }

  void recordReconnectStorm() {
    _reconnectStorms++;
    _talker.error('[Diagnostics] Reconnect storm detected (Total: $_reconnectStorms)');
  }

  void printSummary() {
    _talker.info(
      '--- RUNTIME DIAGNOSTICS ---\n'
      'Replay Gaps: $_replayGaps\n'
      'Rebuilds: $_rebuildCounts\n'
      'Replay Failures: $_replayFailures\n'
      'OCC Conflicts: $_occConflicts\n'
      'Reconnect Storms: $_reconnectStorms\n'
      '---------------------------'
    );
  }
}
