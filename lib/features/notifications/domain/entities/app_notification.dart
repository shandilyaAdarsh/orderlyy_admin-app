// lib/features/notifications/domain/entities/app_notification.dart

enum NotificationSeverity {
  info,
  warning,
  urgent,
  critical,
}

enum NotificationCategory {
  kitchenReady,
  waiterCall,
  paymentCompleted,
  slaBreach,
  reconnectWarning,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationSeverity severity;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, String>? metadata; // Target deep-link params

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationSeverity? severity,
    NotificationCategory? category,
    DateTime? timestamp,
    bool? isRead,
    Map<String, String>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}
