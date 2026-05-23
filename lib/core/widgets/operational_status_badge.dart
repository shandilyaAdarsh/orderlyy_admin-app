// lib/core/widgets/operational_status_badge.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Operational lifecycle states for orders / tables.
enum OperationalStatus {
  preparing,
  delayed,
  ready,
  paymentPending,
  waiterAssigned,
  refunded,
  partiallyPaid,
}

/// Colour-coded badge that communicates an [OperationalStatus] at a glance.
///
/// - [compact]  — uses smaller padding and font size (suited for list rows).
/// - [showIcon] — prepends a small icon to the label text.
class OperationalStatusBadge extends StatefulWidget {
  const OperationalStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
    this.showIcon = true,
  });

  final OperationalStatus status;
  final bool compact;
  final bool showIcon;

  @override
  State<OperationalStatusBadge> createState() => _OperationalStatusBadgeState();
}

class _OperationalStatusBadgeState extends State<OperationalStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _borderOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _borderOpacity = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.status == OperationalStatus.delayed) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(OperationalStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == OperationalStatus.delayed) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _badgeConfig(widget.status);
    final hPad = widget.compact ? 8.0 : 12.0;
    final vPad = widget.compact ? 3.0 : 5.0;
    final fontSize = widget.compact ? 10.0 : 12.0;

    if (widget.status == OperationalStatus.delayed) {
      return AnimatedBuilder(
        animation: _borderOpacity,
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              color: config.backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: config.accentColor.withValues(alpha: _borderOpacity.value),
                width: 1.5,
              ),
            ),
            child: child,
          );
        },
        child: _BadgeContent(
          label: config.label,
          textColor: config.textColor,
          icon: widget.showIcon ? config.icon : null,
          fontSize: fontSize,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: config.accentColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: _BadgeContent(
        label: config.label,
        textColor: config.textColor,
        icon: widget.showIcon ? config.icon : null,
        fontSize: fontSize,
      ),
    );
  }

  _BadgeConfig _badgeConfig(OperationalStatus status) {
    switch (status) {
      case OperationalStatus.preparing:
        const amber = Color(0xFFF59E0B);
        return _BadgeConfig(
          label: 'Preparing',
          icon: Icons.restaurant_menu_rounded,
          textColor: amber,
          backgroundColor: amber.withValues(alpha: 0.15),
          accentColor: amber,
        );

      case OperationalStatus.delayed:
        return _BadgeConfig(
          label: 'Delayed',
          icon: Icons.schedule_rounded,
          textColor: AppColors.error,
          backgroundColor: AppColors.error.withValues(alpha: 0.12),
          accentColor: AppColors.error,
        );

      case OperationalStatus.ready:
        return _BadgeConfig(
          label: 'Ready',
          icon: Icons.check_circle_rounded,
          textColor: AppColors.success,
          backgroundColor: AppColors.success.withValues(alpha: 0.12),
          accentColor: AppColors.success,
        );

      case OperationalStatus.paymentPending:
        const violet = Color(0xFF8B5CF6);
        return _BadgeConfig(
          label: 'Payment Pending',
          icon: Icons.payment_rounded,
          textColor: violet,
          backgroundColor: violet.withValues(alpha: 0.12),
          accentColor: violet,
        );

      case OperationalStatus.waiterAssigned:
        const sky = Color(0xFF0EA5E9);
        return _BadgeConfig(
          label: 'Waiter Assigned',
          icon: Icons.person_pin_circle_rounded,
          textColor: sky,
          backgroundColor: sky.withValues(alpha: 0.12),
          accentColor: sky,
        );

      case OperationalStatus.refunded:
        const rose = Color(0xFFF43F5E);
        return _BadgeConfig(
          label: 'Refunded',
          icon: Icons.undo_rounded,
          textColor: rose,
          backgroundColor: rose.withValues(alpha: 0.12),
          accentColor: rose,
        );

      case OperationalStatus.partiallyPaid:
        const orange = Color(0xFFF97316);
        return _BadgeConfig(
          label: 'Partially Paid',
          icon: Icons.toll_rounded,
          textColor: orange,
          backgroundColor: orange.withValues(alpha: 0.12),
          accentColor: orange,
        );
    }
  }
}

class _BadgeContent extends StatelessWidget {
  const _BadgeContent({
    required this.label,
    required this.textColor,
    required this.fontSize,
    this.icon,
  });

  final String label;
  final Color textColor;
  final double fontSize;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: fontSize + 2, color: textColor),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _BadgeConfig {
  const _BadgeConfig({
    required this.label,
    required this.icon,
    required this.textColor,
    required this.backgroundColor,
    required this.accentColor,
  });

  final String label;
  final IconData icon;
  final Color textColor;
  final Color backgroundColor;
  final Color accentColor;
}
