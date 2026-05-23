import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/dtos/order_dto.dart';
import '../../../../core/providers/orders_providers.dart';
import '../../../../core/providers/repository_providers.dart';

class PollingIntervalController {
  int _consecutiveFailures = 0;

  void recordSuccess() {
    _consecutiveFailures = 0;
  }

  void recordFailure() {
    _consecutiveFailures++;
  }

  Duration getCurrentDelay(OrderDto? order) {
    if (_consecutiveFailures >= 2) {
      // Degraded outage mode: slow down polling to protect battery/gateway
      return const Duration(seconds: 120);
    }

    if (order == null) {
      return const Duration(seconds: 10);
    }

    // Terminal states should not poll frequently
    if (order.status == OrderStatus.cancelled || order.status == OrderStatus.served) {
      return const Duration(seconds: 300);
    }

    final age = DateTime.now().difference(order.createdAt);
    if (age.inMinutes <= 5) {
      return const Duration(seconds: 10);
    } else if (age.inMinutes <= 15) {
      return const Duration(seconds: 30);
    } else {
      return const Duration(seconds: 60);
    }
  }
}

final pollingIntervalControllerProvider = Provider<PollingIntervalController>((ref) {
  return PollingIntervalController();
});

final orderPollingProvider = StreamProvider.family<OrderDto, String>((ref, orderId) async* {
  final repository = ref.watch(ordersRepositoryProvider);
  final controller = ref.watch(pollingIntervalControllerProvider);

  OrderDto? lastOrder;

  while (true) {
    final isOnline = ref.read(isOnlineProvider);
    if (!isOnline) {
      // If offline, wait 120 seconds and check again
      await Future.delayed(const Duration(seconds: 120));
      continue;
    }

    final delay = controller.getCurrentDelay(lastOrder);
    await Future.delayed(delay);

    try {
      final order = await repository.getOrderById(orderId);
      if (order != null) {
        lastOrder = order;
        controller.recordSuccess();
        yield order;

        // Stop polling once order is served or cancelled
        if (order.status == OrderStatus.cancelled || order.status == OrderStatus.served) {
          break;
        }
      } else {
        controller.recordFailure();
      }
    } catch (_) {
      controller.recordFailure();
    }
  }
});
