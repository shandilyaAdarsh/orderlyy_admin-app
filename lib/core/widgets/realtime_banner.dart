// lib/core/widgets/realtime_banner.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Connection / sync status for the realtime channel.
///
/// - [connected]    — channel healthy; render nothing.
/// - [reconnecting] — actively attempting to reconnect.
/// - [replaying]    — replaying missed events post-reconnect.
/// - [degraded]     — offline; operating on cached data.
/// - [critical]     — renders nothing inline; the caller shows a full-screen overlay.
enum RealtimeState { connected, reconnecting, replaying, degraded, critical }

/// A non-blocking top-of-screen (or bottom-of-screen for [RealtimeState.degraded])
/// banner that communicates the live-channel health to the user.
///
/// Intended to be placed inside a [Stack] as the topmost child:
///
/// ```dart
/// Stack(
///   children: [
///     MyMainContent(),
///     RealtimeBanner(
///       state: realtimeState,
///       reconnectAttempt: attemptNumber,
///       onRetry: () => ref.read(channelProvider.notifier).reconnect(),
///     ),
///   ],
/// )
/// ```
class RealtimeBanner extends StatefulWidget {
  const RealtimeBanner({
    super.key,
    required this.state,
    this.reconnectAttempt = 0,
    this.onRetry,
  });

  final RealtimeState state;

  /// Current reconnection attempt counter — shown while [state] is [RealtimeState.reconnecting].
  final int reconnectAttempt;

  /// Callback fired when the user taps "Retry" in degraded mode.
  final VoidCallback? onRetry;

  @override
  State<RealtimeBanner> createState() => _RealtimeBannerState();
}

class _RealtimeBannerState extends State<RealtimeBanner>
    with TickerProviderStateMixin {
  late AnimationController _dotController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _updateVisibility();
  }

  @override
  void didUpdateWidget(RealtimeBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateVisibility();
    }
  }

  void _updateVisibility() {
    final visible = widget.state != RealtimeState.connected &&
        widget.state != RealtimeState.critical;
    if (visible) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  @override
  void dispose() {
    _dotController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.state) {
      case RealtimeState.connected:
      case RealtimeState.critical:
        return const SizedBox.shrink();

      case RealtimeState.reconnecting:
        return _buildReconnectingBanner();

      case RealtimeState.replaying:
        return _buildReplayingBanner();

      case RealtimeState.degraded:
        return _buildDegradedBanner();
    }
  }

  // ── Reconnecting ──────────────────────────────────────────────────────────

  Widget _buildReconnectingBanner() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          height: 44,
          color: const Color(0xFFF59E0B), // amber
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PulsingDots(controller: _dotController),
                const SizedBox(width: 10),
                const Text(
                  'Reconnecting...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1917),
                  ),
                ),
                if (widget.reconnectAttempt > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#${widget.reconnectAttempt}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1C1917),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Replaying ─────────────────────────────────────────────────────────────

  Widget _buildReplayingBanner() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          height: 44,
          color: const Color(0xFF3B82F6), // blue
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Syncing missed events...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Degraded ──────────────────────────────────────────────────────────────

  Widget _buildDegradedBanner() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          height: 52,
          color: AppColors.warning.withValues(alpha: 0.95),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 18,
                  color: Color(0xFF1C1917),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '⚠ Offline Mode — changes will sync when reconnected',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1917),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onRetry != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onRetry,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x33000000),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1917),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated 3-dot indicator ──────────────────────────────────────────────────

class _PulsingDots extends StatelessWidget {
  const _PulsingDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Stagger each dot by 0.2 of the animation period.
            final delay = i * 0.2;
            final t = (controller.value + delay) % 1.0;
            final scale = 0.5 + 0.5 * math.sin(t * math.pi);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1C1917),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
