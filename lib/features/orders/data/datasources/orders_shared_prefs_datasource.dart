import 'dart:async';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/data/dtos/order_dto.dart';

class OrdersSharedPrefsDataSource {
  final LocalStorage _storage;
  static const _key = 'cached_restaurant_orders';
  final _controller = StreamController<List<OrderDto>>.broadcast();

  OrdersSharedPrefsDataSource(this._storage) {
    _init();
  }

  Future<void> _init() async {
    final list = await getCachedOrders();
    _controller.add(list);
  }

  Future<List<OrderDto>> getCachedOrders() async {
    final data = await _storage.read(_key);
    if (data == null) return [];
    final list = data['orders'] as List?;
    if (list == null) return [];
    return list.map((e) => OrderDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<OrderDto?> getCachedOrderById(String id) async {
    final list = await getCachedOrders();
    final index = list.indexWhere((o) => o.id == id);
    return index != -1 ? list[index] : null;
  }

  Future<OrderDto?> getActiveOrderForTable(String tableId) async {
    final list = await getCachedOrders();
    final index = list.indexWhere((o) => o.tableId == tableId && o.status != OrderStatus.served && o.status != OrderStatus.cancelled);
    return index != -1 ? list[index] : null;
  }

  Future<void> cacheOrders(List<OrderDto> orders) async {
    await _storage.write(_key, {'orders': orders.map((o) => o.toJson()).toList()});
    _controller.add(orders);
  }

  Future<void> cacheOrder(OrderDto order) async {
    final list = await getCachedOrders();
    final index = list.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      list[index] = order;
    } else {
      list.add(order);
    }
    await cacheOrders(list);
  }

  Stream<List<OrderDto>> watchCachedOrders() {
    return _controller.stream;
  }
}
