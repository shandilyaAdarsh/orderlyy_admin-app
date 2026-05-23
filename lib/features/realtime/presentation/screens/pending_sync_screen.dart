// lib/features/realtime/presentation/screens/pending_sync_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/sync_operation.dart';
import '../state/realtime_providers.dart';

class PendingSyncScreen extends ConsumerStatefulWidget {
  const PendingSyncScreen({super.key});

  @override
  ConsumerState<PendingSyncScreen> createState() => _PendingSyncScreenState();
}

class _PendingSyncScreenState extends ConsumerState<PendingSyncScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Periodically update the relative timestamps
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _getRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.isNegative || diff.inSeconds < 5) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  IconData _getIconForType(SyncOperationType type) {
    switch (type) {
      case SyncOperationType.acknowledgeCall:
      case SyncOperationType.resolveCall:
      case SyncOperationType.escalateCall:
      case SyncOperationType.createCall:
        return Icons.campaign_rounded;
      case SyncOperationType.updateTableStatus:
        return Icons.table_restaurant_rounded;
      case SyncOperationType.saveOrder:
        return Icons.restaurant_menu_rounded;
    }
  }

  Color _getStatusColor(SyncOperationStatus status) {
    switch (status) {
      case SyncOperationStatus.queued:
        return Colors.grey;
      case SyncOperationStatus.inflight:
        return Colors.blue;
      case SyncOperationStatus.success:
        return AppColors.success;
      case SyncOperationStatus.failed:
        return AppColors.error;
      case SyncOperationStatus.conflict:
        return const Color(0xFF8B5CF6); // violet
      case SyncOperationStatus.retrying:
        return AppColors.warning;
      case SyncOperationStatus.discarded:
        return Colors.red.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(syncQueueProvider);
    final pendingCount = ref.watch(pendingOpsCountProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Filter queue to remove success & discarded if not needed, but keep them for UI representation
    // Spec: "Shows the offline write queue."
    final activeQueue = queue.where((op) => 
      op.status != SyncOperationStatus.success && 
      op.status != SyncOperationStatus.discarded
    ).toList();

    // Summary counts
    final inflightCount = activeQueue.where((op) => op.status == SyncOperationStatus.inflight).length;
    final retryingCount = activeQueue.where((op) => op.status == SyncOperationStatus.retrying).length;
    final failedCount = activeQueue.where((op) => op.status == SyncOperationStatus.failed || op.status == SyncOperationStatus.conflict).length;

    // Filtered lists for tabs: All | Orders | Calls | Failed
    final allOps = activeQueue;
    final ordersOps = activeQueue.where((op) => op.type == SyncOperationType.saveOrder).toList();
    final callsOps = activeQueue.where((op) => 
      op.type == SyncOperationType.acknowledgeCall || 
      op.type == SyncOperationType.resolveCall ||
      op.type == SyncOperationType.escalateCall ||
      op.type == SyncOperationType.createCall
    ).toList();
    final failedOps = activeQueue.where((op) => 
      op.status == SyncOperationStatus.failed || 
      op.status == SyncOperationStatus.conflict
    ).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Sync Queue',
              style: AppTextStyles.h3.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (pendingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        centerTitle: false,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: AppTextStyles.bodyMedium,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Orders'),
            Tab(text: 'Calls'),
            Tab(text: 'Failed'),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ── Summary Card ─────────────────────────────────────────────────
          _buildSummaryCard(
            inflightCount: inflightCount,
            retryingCount: retryingCount,
            failedCount: failedCount,
            totalCount: activeQueue.length,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          
          // ── Tabs content ─────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQueueList(allOps, 'No operations in sync queue', Icons.cloud_done_rounded, surfaceColor, borderColor, textPrimary, textSecondary),
                _buildQueueList(ordersOps, 'No pending order syncs', Icons.restaurant_menu_rounded, surfaceColor, borderColor, textPrimary, textSecondary),
                _buildQueueList(callsOps, 'No pending waiter calls', Icons.campaign_rounded, surfaceColor, borderColor, textPrimary, textSecondary),
                _buildQueueList(failedOps, 'No failed operations', Icons.check_circle_outline_rounded, surfaceColor, borderColor, textPrimary, textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required int inflightCount,
    required int retryingCount,
    required int failedCount,
    required int totalCount,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total', '$totalCount', Colors.blue, textSecondary),
          _buildSummaryDivider(borderColor),
          _buildSummaryItem('In-flight', '$inflightCount', Colors.amber, textSecondary),
          _buildSummaryDivider(borderColor),
          _buildSummaryItem('Retrying', '$retryingCount', AppColors.warning, textSecondary),
          _buildSummaryDivider(borderColor),
          _buildSummaryItem('Failed', '$failedCount', AppColors.error, textSecondary),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, Color textSecondary) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h2.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: textSecondary),
        ),
      ],
    );
  }

  Widget _buildSummaryDivider(Color borderColor) {
    return Container(
      height: 32,
      width: 1,
      color: borderColor,
    );
  }

  Widget _buildQueueList(
    List<SyncOperation> ops,
    String emptyMessage,
    IconData emptyIcon,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (ops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: AppTextStyles.bodyLarge.copyWith(color: textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: ops.length,
      itemBuilder: (context, index) {
        final op = ops[index];
        return _buildSyncOpCard(op, surfaceColor, borderColor, textPrimary, textSecondary);
      },
    );
  }

  Widget _buildSyncOpCard(
    SyncOperation op,
    Color surfaceColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final statusColor = _getStatusColor(op.status);
    final isFailed = op.status == SyncOperationStatus.failed;
    final isConflict = op.status == SyncOperationStatus.conflict;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: statusColor, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Icon + Label + Status badge
              Row(
                children: [
                  Icon(_getIconForType(op.type), color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      op.entityLabel,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  _buildStatusBadge(op.status, statusColor),
                ],
              ),
              const SizedBox(height: 12),
              
              // Body info: Timestamp, Retries, Errors
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _getRelativeTime(op.queuedAt),
                    style: AppTextStyles.caption.copyWith(color: textSecondary),
                  ),
                  if (op.retryCount > 0) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.replay_rounded, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Retries: ${op.retryCount}/${op.maxRetries}',
                      style: AppTextStyles.caption.copyWith(color: textSecondary),
                    ),
                  ],
                ],
              ),
              
              if (op.errorMessage != null && op.errorMessage!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    op.errorMessage!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              // Actions buttons for Failed / Conflict
              if (isFailed || isConflict) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isFailed) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textSecondary,
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Discard'),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          ref.read(syncQueueProvider.notifier).discardOperation(op.operationId);
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          ref.read(syncQueueProvider.notifier).retryOperation(op.operationId);
                        },
                      ),
                    ] else if (isConflict) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.merge_type_rounded, size: 16),
                        label: const Text('Resolve Conflict'),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _showConflictResolutionDialog(context, op);
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SyncOperationStatus status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  void _showConflictResolutionDialog(BuildContext context, SyncOperation op) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: const Text('Conflict Detected', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A sync conflict occurred on the server for:',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              op.entityLabel,
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose how to resolve the conflict:',
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ref.read(syncQueueProvider.notifier).discardOperation(op.operationId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Operation discarded. Server state kept.')),
                      );
                    },
                    child: const Text('Keep Server'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ref.read(syncQueueProvider.notifier).markSuccess(op.operationId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Conflict resolved by overwriting server.')),
                      );
                    },
                    child: const Text('Overwrite Server'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
