import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class WaiterOrdersScreen extends StatefulWidget {
  const WaiterOrdersScreen({super.key});

  @override
  State<WaiterOrdersScreen> createState() => _WaiterOrdersScreenState();
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
        title: Text('My Orders',
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined, color: AppTheme.secondary), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Filter pills
          Container(
            color: AppTheme.surfaceContainerLowest,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: List.generate(_filters.length, (i) {
                final active = _filterIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _filterIndex = i),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primaryContainer : AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_filters[i],
                        style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: active ? Colors.white : AppTheme.secondary, letterSpacing: 0.8,
                        )),
                  ),
                );
              }),
            ),
          ),

          // Orders list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // COOKING card
                _WaiterOrderCard(
                  tableInfo: 'Table 12 · Main Hall',
                  orderId: '#ORD-2841',
                  status: _WaiterOrderStatus.cooking,
                  items: const [
                    ('2×', 'Mutton Rogan Josh', '₹780'),
                    ('1×', 'Garlic Naan Basket', '₹120'),
                    ('2×', 'Mango Lassi', '₹220'),
                  ],
                  totalAmount: '₹1,120',
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 12),

                // READY card
                _WaiterOrderCard(
                  tableInfo: 'Table 04 · Patio',
                  orderId: '#ORD-2845',
                  status: _WaiterOrderStatus.ready,
                  items: const [
                    ('1×', 'Paneer Tikka Starter', '₹320'),
                    ('2×', 'Masala Cola', '₹110'),
                  ],
                  totalAmount: '₹540',
                ).animate(delay: 80.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 12),

                // SERVED card
                _WaiterOrderCard(
                  tableInfo: 'Table 07 · Private Room',
                  orderId: '#ORD-2838',
                  status: _WaiterOrderStatus.served,
                  items: const [
                    ('1×', 'Dal Makhani', '₹280'),
                    ('2×', 'Butter Naan', '₹80'),
                    ('1×', 'Gulab Jamun', '₹160'),
                  ],
                  totalAmount: '₹2,340',
                ).animate(delay: 160.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
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

  const _WaiterOrderCard({
    required this.tableInfo,
    required this.orderId,
    required this.status,
    required this.items,
    required this.totalAmount,
  });

  Color get _borderColor => switch (status) {
        _WaiterOrderStatus.cooking => AppTheme.primaryContainer,
        _WaiterOrderStatus.ready   => const Color(0xFF0D9488),
        _WaiterOrderStatus.served  => const Color(0xFFCBD5E1),
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
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tableInfo,
                          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
                      Text(orderId,
                          style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppTheme.secondary, letterSpacing: 0.5)),
                    ]),
                    // Status badge
                    if (isCooking)
                      _CookingBadge()
                    else if (isReady)
                      _ReadyBadge()
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(color: AppTheme.surfaceContainer, borderRadius: BorderRadius.circular(20)),
                        child: Text('SERVED',
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800,
                                color: AppTheme.secondary, letterSpacing: 0.8)),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  // Items
                  ...items.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Text(i.$1, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppTheme.secondary)),
                          const SizedBox(width: 8),
                          Text(i.$2, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.onSurface)),
                        ]),
                        Text(i.$3, style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppTheme.secondary)),
                      ],
                    ),
                  )),
                  const Divider(color: AppTheme.surfaceContainerLow, thickness: 1, height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('ORDER TOTAL',
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
                            color: AppTheme.secondary, letterSpacing: 1)),
                    Text(totalAmount,
                        style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
                  ]),
                ],
              ),
            ),

            // Bottom action
            if (!isServed)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(children: [
                  if (isCooking) ...[
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.surfaceContainerHigh),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Add Item',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.secondary)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 40, width: 40,
                      decoration: BoxDecoration(color: AppTheme.surfaceContainer, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.secondary, size: 18),
                    ),
                  ] else if (isReady)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {},
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.restaurant_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text('Serve Now',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                          ]),
                        ),
                      ),
                    ),
                ]),
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
      child: Row(children: [
        SizedBox(
          width: 8, height: 8,
          child: Stack(alignment: Alignment.center, children: [
            Container(width: 8, height: 8,
                decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle))
                .animate(onPlay: (c) => c.repeat()).fadeOut(duration: 900.ms),
            Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle)),
          ]),
        ),
        const SizedBox(width: 6),
        Text('COOKING',
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800,
                color: AppTheme.error, letterSpacing: 0.8)),
      ]),
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
      child: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 12),
        const SizedBox(width: 6),
        Text('READY TO SERVE',
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800,
                color: const Color(0xFF065F46), letterSpacing: 0.8)),
      ]),
    );
  }
}
