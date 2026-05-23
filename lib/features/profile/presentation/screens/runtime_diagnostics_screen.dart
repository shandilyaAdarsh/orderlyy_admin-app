// lib/features/profile/presentation/screens/runtime_diagnostics_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class DiagnosticsData {
  final bool isConnected;
  final int lastPingMs;
  final int reconnectCount;
  final int messagesSent;
  final int messagesReceived;
  final int p50Ms;
  final int p95Ms;
  final int p99Ms;
  final DateTime lastSnapshotAt;
  final int eventsReceived;
  final int eventsReplayed;
  final int duplicatesDiscarded;
  final int queueDepth;
  final int failedOps;
  final String appVersion;

  const DiagnosticsData({
    required this.isConnected,
    required this.lastPingMs,
    required this.reconnectCount,
    required this.messagesSent,
    required this.messagesReceived,
    required this.p50Ms,
    required this.p95Ms,
    required this.p99Ms,
    required this.lastSnapshotAt,
    required this.eventsReceived,
    required this.eventsReplayed,
    required this.duplicatesDiscarded,
    required this.queueDepth,
    required this.failedOps,
    required this.appVersion,
  });

  DiagnosticsData copyWith({
    bool? isConnected,
    int? lastPingMs,
    int? reconnectCount,
    int? messagesSent,
    int? messagesReceived,
    int? p50Ms,
    int? p95Ms,
    int? p99Ms,
    DateTime? lastSnapshotAt,
    int? eventsReceived,
    int? eventsReplayed,
    int? duplicatesDiscarded,
    int? queueDepth,
    int? failedOps,
    String? appVersion,
  }) {
    return DiagnosticsData(
      isConnected: isConnected ?? this.isConnected,
      lastPingMs: lastPingMs ?? this.lastPingMs,
      reconnectCount: reconnectCount ?? this.reconnectCount,
      messagesSent: messagesSent ?? this.messagesSent,
      messagesReceived: messagesReceived ?? this.messagesReceived,
      p50Ms: p50Ms ?? this.p50Ms,
      p95Ms: p95Ms ?? this.p95Ms,
      p99Ms: p99Ms ?? this.p99Ms,
      lastSnapshotAt: lastSnapshotAt ?? this.lastSnapshotAt,
      eventsReceived: eventsReceived ?? this.eventsReceived,
      eventsReplayed: eventsReplayed ?? this.eventsReplayed,
      duplicatesDiscarded: duplicatesDiscarded ?? this.duplicatesDiscarded,
      queueDepth: queueDepth ?? this.queueDepth,
      failedOps: failedOps ?? this.failedOps,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final diagnosticsProvider = StateProvider<DiagnosticsData>((ref) => DiagnosticsData(
      isConnected: true,
      lastPingMs: 87,
      reconnectCount: 1,
      messagesSent: 234,
      messagesReceived: 1247,
      p50Ms: 94,
      p95Ms: 187,
      p99Ms: 312,
      lastSnapshotAt: DateTime.now().subtract(const Duration(minutes: 8)),
      eventsReceived: 412,
      eventsReplayed: 23,
      duplicatesDiscarded: 2,
      queueDepth: 0,
      failedOps: 0,
      appVersion: '2.1.0+42',
    ));

// ─── Screen ───────────────────────────────────────────────────────────────────

class RuntimeDiagnosticsScreen extends ConsumerStatefulWidget {
  const RuntimeDiagnosticsScreen({super.key});

  @override
  ConsumerState<RuntimeDiagnosticsScreen> createState() => _RuntimeDiagnosticsScreenState();
}

class _RuntimeDiagnosticsScreenState extends ConsumerState<RuntimeDiagnosticsScreen> {
  Timer? _refreshTimer;
  DateTime _lastRefreshTime = DateTime.now();
  final _random = math.Random();
  final List<double> _sparklineHeights = [20, 35, 15, 45, 60, 25, 40, 55, 30, 48];

  @override
  void initState() {
    super.initState();
    // Simulate live data updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _simulateMetricsUpdate();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _simulateMetricsUpdate() {
    _lastRefreshTime = DateTime.now();
    ref.read(diagnosticsProvider.notifier).update((state) {
      final pingNoise = _random.nextInt(30) - 15;
      final newPing = (state.lastPingMs + pingNoise).clamp(35, 450);
      final sentAdd = _random.nextInt(4) + 1;
      final recvAdd = _random.nextInt(12) + 2;
      
      // Randomly adjust sparkline values to simulate traffic
      setState(() {
        _sparklineHeights.removeAt(0);
        _sparklineHeights.add((_random.nextDouble() * 50 + 15).clamp(10, 70));
      });

      return state.copyWith(
        lastPingMs: newPing,
        messagesSent: state.messagesSent + sentAdd,
        messagesReceived: state.messagesReceived + recvAdd,
        eventsReceived: state.eventsReceived + (_random.nextInt(3) == 0 ? 1 : 0),
      );
    });
  }

  void _handleManualRefresh() {
    HapticFeedback.mediumImpact();
    _simulateMetricsUpdate();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostics refreshed'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportDiagnostics(DiagnosticsData data) {
    HapticFeedback.heavyImpact();
    final report = '''
ORDERLLI DIAGNOSTICS REPORT
----------------------------
App Version: ${data.appVersion}
Device ID: anon-8f3a2c
Timestamp: ${DateTime.now().toIso8601String()}

WEBSOCKET HEALTH
Connection: ${data.isConnected ? 'CONNECTED' : 'DISCONNECTED'}
Last Ping: ${data.lastPingMs} ms
Reconnect Count: ${data.reconnectCount}
Messages Sent: ${data.messagesSent}
Messages Received: ${data.messagesReceived}

API LATENCY
P50: ${data.p50Ms} ms
P95: ${data.p95Ms} ms
P99: ${data.p99Ms} ms

SYNC HEALTH
Last Snapshot: ${data.lastSnapshotAt.toIso8601String()}
Events Received: ${data.eventsReceived}
Events Replayed: ${data.eventsReplayed}
Duplicates Discarded: ${data.duplicatesDiscarded}
Queue Depth: ${data.queueDepth}
Failed Ops: ${data.failedOps}
''';

    Clipboard.setData(ClipboardData(text: report));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostics report copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getPingColor(int ping) {
    if (ping < 100) return AppColors.success;
    if (ping < 300) return AppColors.warning;
    return AppColors.error;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(diagnosticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Runtime Diagnostics',
          style: AppTextStyles.h3.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Export',
            onPressed: () => _exportDiagnostics(data),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Device / App Header Card ──────────────────────────────────────
          _buildHeaderCard(data, surfaceColor, borderColor, textPrimary, textSecondary),
          const SizedBox(height: 20),

          // ── WEBSOCKET HEALTH ──────────────────────────────────────────────
          _buildSectionHeader('WEBSOCKET HEALTH', textSecondary),
          _buildDiagnosticsContainer(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildDiagnosticRow(
                'Connection Status',
                trailingWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (data.isConnected ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: (data.isConnected ? AppColors.success : AppColors.error).withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    data.isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      color: data.isConnected ? AppColors.success : AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                textPrimary: textPrimary,
              ),
              _divider(borderColor),
              _buildDiagnosticRow(
                'Last Ping',
                trailingText: '${data.lastPingMs} ms',
                trailingColor: _getPingColor(data.lastPingMs),
                textPrimary: textPrimary,
              ),
              _divider(borderColor),
              _buildDiagnosticRow(
                'Reconnect Count',
                trailingText: '${data.reconnectCount}',
                textPrimary: textPrimary,
              ),
              _divider(borderColor),
              _buildDiagnosticRow(
                'Messages Sent',
                trailingText: '${data.messagesSent}',
                textPrimary: textPrimary,
              ),
              _divider(borderColor),
              _buildDiagnosticRow(
                'Messages Received',
                trailingText: '${data.messagesReceived}',
                textPrimary: textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── API LATENCY ───────────────────────────────────────────────────
          _buildSectionHeader('API LATENCY', textSecondary),
          _buildDiagnosticsContainer(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildDiagnosticRow(
                'P50 Latency',
                trailingText: '${data.p50Ms} ms',
                trailingColor: AppColors.success,
                textPrimary: textPrimary,
              ),
              _divider(borderColor),
              _buildDiagnosticRow(
                'P95 Latency',
                trailingText: '${data.p95Ms} ms',
                trailingColor: AppColors.warning,
                textPrimary: textPrimary,
              ),
              _divider(borderColor),
              _buildDiagnosticRow(
                'P99 Latency',
                trailingText: '${data.p99Ms} ms',
                trailingColor: AppColors.error,
                textPrimary: textPrimary,
              ),
              _divider(borderColor),
              
              // Sparkline chart
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Latency Timeline',
                      style: AppTextStyles.caption.copyWith(color: textSecondary),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 72,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: _sparklineHeights.map((h) {
                          // Color code each bar in sparkline based on height
                          final barColor = h > 50 
                              ? AppColors.error 
                              : h > 30 
                                  ? AppColors.warning 
                                  : AppColors.success;
                          return Container(
                            width: 22,
                            height: h,
                            decoration: BoxDecoration(
                              color: barColor.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── SYNC HEALTH ───────────────────────────────────────────────────
          _buildSectionHeader('SYNC HEALTH', textSecondary),
          _buildDiagnosticsContainer(
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            children: [
              _buildDiagnosticRow(
                'Last Snapshot',
                trailingText: '8 min ago',
                textPrimary: textPrimary,
              ),
              _divider(borderColor),
              _buildDiagnosticRow(
                'Events Received',
                trailingText: '${data.eventsReceived}',
                textPrimary: textPrimary,
              ),
              _divider(borderColor),
              _buildDiagnosticRow(
                'Events Replayed',
                trailingText: '${data.eventsReplayed}',
                textPrimary: textPrimary,
              ),
              _divider(borderColor),
              _buildDiagnosticRow(
                'Duplicates Discarded',
                trailingText: '${data.duplicatesDiscarded}',
                textPrimary: textPrimary,
              ),
              _divider(borderColor),
              _buildDiagnosticRow(
                'Queue Depth',
                trailingText: '${data.queueDepth}',
                trailingColor: AppColors.success,
                textPrimary: textPrimary,
              ),
              _divider(borderColor),
              _buildDiagnosticRow(
                'Failed Operations',
                trailingText: '${data.failedOps}',
                trailingColor: AppColors.success,
                textPrimary: textPrimary,
              ),
            ],
          ),
          
          const SizedBox(height: 32),

          // ── Action Buttons ───────────────────────────────────────────────
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh Now', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _handleManualRefresh,
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Auto-refreshing every 5s · Last: ${_formatTime(_lastRefreshTime)}',
              style: AppTextStyles.caption.copyWith(color: textSecondary),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    DiagnosticsData data,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App Version',
                style: AppTextStyles.caption.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                data.appVersion,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: textPrimary),
              ),
            ],
          ),
          Container(
            height: 32,
            width: 1,
            color: borderColor,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device ID',
                style: AppTextStyles.caption.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'anon-8f3a2c',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: textPrimary),
              ),
            ],
          ),
          Container(
            height: 32,
            width: 1,
            color: borderColor,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Environment',
                style: AppTextStyles.caption.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'PROD-STAGE',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.warning),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDiagnosticsContainer({
    required Color surfaceColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDiagnosticRow(
    String label, {
    String? trailingText,
    Color? trailingColor,
    Widget? trailingWidget,
    required Color textPrimary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: textPrimary, fontWeight: FontWeight.w500),
          ),
          if (trailingWidget != null)
            trailingWidget
          else if (trailingText != null)
            Text(
              trailingText,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: trailingColor ?? textPrimary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _divider(Color color) {
    return Divider(height: 1, indent: 16, color: color);
  }
}
