// lib/features/notifications/presentation/state/notifications_provider.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_notification.dart';

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super([]) {
    _populateInitialMockNotifications();
  }

  void _populateInitialMockNotifications() {
    final now = DateTime.now();
    state = [
      AppNotification(
        id: 'notif_1',
        title: 'Table 12: Mains Ready',
        message: '2x Cheeseburger (Grill) is ready for pickup.',
        severity: NotificationSeverity.urgent,
        category: NotificationCategory.kitchenReady,
        timestamp: now.subtract(const Duration(minutes: 2)),
        metadata: {'tableId': '12', 'orderId': 'ord_12'},
      ),
      AppNotification(
        id: 'notif_2',
        title: 'Table 5: Bill Request',
        message: 'Guest requested receipt payment (Mastercard).',
        severity: NotificationSeverity.urgent,
        category: NotificationCategory.waiterCall,
        timestamp: now.subtract(const Duration(minutes: 8)),
        metadata: {'tableId': '5'},
      ),
      AppNotification(
        id: 'notif_3',
        title: 'SLA Breach Warning',
        message: 'Table 3 Main items in Grill station exceed 15 mins cooking SLA.',
        severity: NotificationSeverity.critical,
        category: NotificationCategory.slaBreach,
        timestamp: now.subtract(const Duration(minutes: 10)),
        metadata: {'tableId': '3'},
      ),
      AppNotification(
        id: 'notif_4',
        title: 'Network Reconnected',
        message: 'Sync manager restored local offline cache.',
        severity: NotificationSeverity.info,
        category: NotificationCategory.reconnectWarning,
        timestamp: now.subtract(const Duration(minutes: 15)),
        isRead: true,
      ),
    ];
  }

  // Deduplication logic using temporary buffers
  final Map<String, Timer> _dedupTimers = {};

  void triggerNotification({
    required String title,
    required String message,
    required NotificationSeverity severity,
    required NotificationCategory category,
    Map<String, String>? metadata,
  }) {
    // If a notification with the same title and category is triggered within 500ms, deduplicate
    final dedupKey = '${category.name}_$title';
    if (_dedupTimers.containsKey(dedupKey)) {
      _dedupTimers[dedupKey]?.cancel();
    }

    _dedupTimers[dedupKey] = Timer(const Duration(milliseconds: 500), () {
      final notif = AppNotification(
        id: 'notif_${Random().nextInt(1000000)}',
        title: title,
        message: message,
        severity: severity,
        category: category,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      state = [notif, ...state];
      _dedupTimers.remove(dedupKey);

      // Perform haptic escalations based on severity
      _executeHapticsForSeverity(severity);
    });
  }

  void _executeHapticsForSeverity(NotificationSeverity severity) {
    switch (severity) {
      case NotificationSeverity.info:
        HapticFeedback.lightImpact();
        break;
      case NotificationSeverity.warning:
        HapticFeedback.mediumImpact();
        break;
      case NotificationSeverity.urgent:
        HapticFeedback.vibrate();
        break;
      case NotificationSeverity.critical:
        // Double heavy pulse pattern
        HapticFeedback.heavyImpact().then((_) {
          Future.delayed(const Duration(milliseconds: 100), () {
            HapticFeedback.heavyImpact();
          });
        });
        break;
    }
  }

  void markAsRead(String id) {
    state = state.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  void clearNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void clearAll() {
    state = [];
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
  return NotificationsNotifier();
});

// Derived provider for unread notifications count
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider);
  return list.where((n) => !n.isRead).length;
});
