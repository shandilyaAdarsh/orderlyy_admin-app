// lib/core/widgets/sync_state_chip.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/sync_state.dart';
import '../theme/app_colors.dart';

/// A compact status chip that reflects the current [SyncState].
///
/// Pass [overrideState] directly when you have the value at hand.
/// If [overrideState] is null, the widget renders [SizedBox.shrink()].
///
/// Usage:
/// ```dart
/// SyncStateChip(overrideState: SyncState.stale)
/// ```
class SyncStateChip extends ConsumerWidget {
  const SyncStateChip({
    super.key,
    this.overrideState,
  });

  /// When non-null, drives the chip appearance.
  /// When null, the chip is invisible.
  final SyncState? overrideState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = overrideState;
    if (state == null || state == SyncState.fresh) {
      return const SizedBox.shrink();
    }
    return _SyncStateChipContent(syncState: state);
  }
}

class _SyncStateChipContent extends StatelessWidget {
  const _SyncStateChipContent({required this.syncState});

  final SyncState syncState;

  @override
  Widget build(BuildContext context) {
    final config = _chipConfig(syncState);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (syncState == SyncState.replaying) ...[
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(config.textColor),
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            config.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: config.textColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _ChipConfig _chipConfig(SyncState state) {
    switch (state) {
      case SyncState.fresh:
        // Should never reach here — filtered above.
        return _ChipConfig(
          label: '● Live',
          textColor: AppColors.success,
          backgroundColor: AppColors.success.withValues(alpha: 0.12),
          borderColor: AppColors.success.withValues(alpha: 0.3),
        );

      case SyncState.stale:
        const amber = Color(0xFFF59E0B);
        return _ChipConfig(
          label: '● Stale',
          textColor: amber,
          backgroundColor: amber.withValues(alpha: 0.12),
          borderColor: amber.withValues(alpha: 0.3),
        );

      case SyncState.replaying:
        const blue = Color(0xFF3B82F6);
        return _ChipConfig(
          label: 'Syncing...',
          textColor: blue,
          backgroundColor: blue.withValues(alpha: 0.12),
          borderColor: blue.withValues(alpha: 0.3),
        );

      case SyncState.degraded:
        return _ChipConfig(
          label: '⚠ Offline',
          textColor: AppColors.warning,
          backgroundColor: AppColors.warning.withValues(alpha: 0.12),
          borderColor: AppColors.warning.withValues(alpha: 0.3),
        );

      case SyncState.unknown:
        const grey = Color(0xFF9CA3AF);
        return _ChipConfig(
          label: '○ Connecting',
          textColor: grey,
          backgroundColor: grey.withValues(alpha: 0.10),
          borderColor: grey.withValues(alpha: 0.25),
        );
    }
  }
}

class _ChipConfig {
  const _ChipConfig({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
}
