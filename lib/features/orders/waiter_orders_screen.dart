import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_theme.dart';

class WaiterOrdersScreen extends StatefulWidget {
  const WaiterOrdersScreen({super.key});

  @override
  State<WaiterOrdersScreen> createState() => _WaiterOrdersScreenState();
}

String _normalizeOrderStatus(dynamic status) {
  final raw = status?.toString().toLowerCase().trim() ?? '';
  if (raw == 'rejected' || raw == 'completed') return 'served';
  if (raw.isEmpty) return 'pending';
  return raw;
}

String _displayTableLabel(Map<String, dynamic> order) {
  final tableNum =
      order['table_num'] ??
      order['table_number'] ??
      order['tableNo'] ??
      order['table'];
  if (tableNum != null) {
    final numStr = tableNum.toString().padLeft(2, '0');
    return 'Table $numStr';
  }

  final rawId = order['table_id']?.toString() ?? '';
  if (rawId.isNotEmpty && rawId.length <= 4) return 'Table $rawId';
  return 'Table ?';
}

class _WaiterOrdersScreenState extends State<WaiterOrdersScreen> {
  int _filterIndex = 0;
  static const _filters = ['ALL', 'ACTIVE', 'SERVED'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'My Orders',
          style: GoogleFonts.inter(
            fontSize: 22.r,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: AppTheme.secondary,
              size: 24.r,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          Stream<List<Map<String, dynamic>>> ordersStream;
          try {
            ordersStream = Supabase.instance.client.from('orders').stream(primaryKey: ['id']);
          } catch (e) {
            debugPrint('Orders realtime stream unavailable: $e');
            ordersStream = Stream.fromFuture(Future(() async {
              try {
                final data = await Supabase.instance.client.from('orders').select();
                return List<Map<String, dynamic>>.from(data.cast<Map>());
              } catch (e) {
                debugPrint('Orders one-shot fetch failed: $e');
              }
              return <Map<String, dynamic>>[];
            }));
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: ordersStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('Orders Sync Error: ${snapshot.error}');
                return Center(
                  child: Text('Orders Sync Error: ${snapshot.error}', style: GoogleFonts.inter(color: AppTheme.error)),
                );
              }
              final allOrders = snapshot.data ?? [];

          // Filter logic for waiter: ACTIVE (Pending, Cooking, Ready) or SERVED
          final orders = allOrders.where((o) {
            final status = _normalizeOrderStatus(o['status']);
            if (_filterIndex == 0) return true; // ALL
            if (_filterIndex == 1) {
              return ['pending', 'cooking', 'ready'].contains(status); // ACTIVE
            }
            if (_filterIndex == 2) return status == 'served'; // SERVED
            return true;
          }).toList();

          return Column(
            children: [
              // Filter pills
              Container(
                color: AppTheme.surfaceContainerLowest,
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                child: Row(
                  children: List.generate(_filters.length, (i) {
                    final active = _filterIndex == i;
                    return GestureDetector(
                      onTap: () => setState(() => _filterIndex = i),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        margin: EdgeInsets.only(right: 8.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.primaryContainer
                              : AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          _filters[i],
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : AppTheme.secondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Orders list
              Expanded(
                child: orders.isEmpty
                    ? Center(
                        child: Text(
                          'No orders found',
                          style: GoogleFonts.inter(color: AppTheme.secondary),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                        itemCount: orders.length,
                        itemBuilder: (context, i) {
                          final o = orders[i];
                          final statusStr = _normalizeOrderStatus(o['status']);
                          final status = statusStr == 'cooking'
                              ? _WaiterOrderStatus.cooking
                              : statusStr == 'ready'
                              ? _WaiterOrderStatus.ready
                              : _WaiterOrderStatus.served;

                          final items = (o['items'] as List? ?? []).map((item) {
                            final name = item is Map
                                ? (item['name'] ?? 'Item')
                                : item.toString();
                            final qty = item is Map
                                ? (item['quantity'] ?? 1)
                                : 1;
                            final price = item is Map
                                ? '₹${item['price'] ?? ''}'
                                : '';
                            return ('$qty×', name.toString(), price.toString());
                          }).toList();

                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: _WaiterOrderCard(
                              tableInfo: _displayTableLabel(o),
                               orderId: (() {
                                 final rawId = o['id']?.toString() ?? '';
                                 return '#${(rawId.length >= 8 ? rawId.substring(0, 8) : rawId).toUpperCase()}';
                               })(),
                              status: status,
                              items: items,
                              totalAmount: '₹${o['total_amount'] ?? '0'}',
                              orderMap: o,
                            ).animate().fadeIn(duration: 400.ms),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      );
    }),
  );
}
}

enum _WaiterOrderStatus { cooking, ready, served }

class _WaiterOrderCard extends StatelessWidget {
  final String tableInfo;
  final String orderId;
  final _WaiterOrderStatus status;
  final List<(String, String, String)> items;
  final String totalAmount;
  final Map<String, dynamic> orderMap;

  const _WaiterOrderCard({
    required this.tableInfo,
    required this.orderId,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.orderMap,
  });

  Future<void> _serveOrder(BuildContext context) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': 'served'})
          .eq('id', orderMap['id']);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Order $orderId served!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error serving order: $e')));
      }
    }
  }

  Color get _borderColor => switch (status) {
    _WaiterOrderStatus.cooking => AppTheme.primaryContainer,
    _WaiterOrderStatus.ready => const Color(0xFF0D9488),
    _WaiterOrderStatus.served => const Color(0xFFCBD5E1),
  };

  @override
  Widget build(BuildContext context) {
    final isServed = status == _WaiterOrderStatus.served;
    final isCooking = status == _WaiterOrderStatus.cooking;
    final isReady = status == _WaiterOrderStatus.ready;

    return Opacity(
      opacity: isServed ? 0.75 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: AppTheme.radiusMd,
          border: Border(left: BorderSide(color: _borderColor, width: 4)),
          boxShadow: isServed ? null : AppTheme.crimsonShadowLight,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tableInfo,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          Text(
                            orderId,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: AppTheme.secondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      // Status badge
                      if (isCooking)
                        _CookingBadge()
                      else if (isReady)
                        _ReadyBadge()
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'SERVED',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.secondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Items
                  ...items.map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                i.$1,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  color: AppTheme.secondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                i.$2,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            i.$3,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                    color: AppTheme.surfaceContainerLow,
                    thickness: 1,
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ORDER TOTAL',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondary,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        totalAmount,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom action
            if (!isServed)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    if (isCooking) ...[
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppTheme.surfaceContainerHigh,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Add Item',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppTheme.secondary,
                          size: 18,
                        ),
                      ),
                    ] else if (isReady)
                      Expanded(
                        child: SizedBox(
                          height: 48.h,
                          child: ElevatedButton(
                            onPressed: () => _serveOrder(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.restaurant_rounded, size: 18.r),
                                SizedBox(width: 8.w),
                                Text(
                                  'Serve Now',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CookingBadge extends StatelessWidget {
  const _CookingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 8,
            height: 8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 900.ms),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'COOKING',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppTheme.error,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyBadge extends StatelessWidget {
  const _ReadyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF059669),
            size: 12,
          ),
          const SizedBox(width: 6),
          Text(
            'READY TO SERVE',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF065F46),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
