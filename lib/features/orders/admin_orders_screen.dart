import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  int _filterIndex = 0;
  static const _filters = ['ALL', 'PENDING', 'COOKING', 'READY', 'SERVED'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client.from('orders').stream(primaryKey: ['id']),
          builder: (context, snapshot) {
            final orders = snapshot.data ?? [];
            
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppTheme.surfaceContainerLowest,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 64.h,
                  title: Row(children: [
                    Text('Orderlli',
                        style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(width: 8.w),
                    Container(width: 1.w, height: 18.h, color: AppTheme.surfaceContainerHighest),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text('Live Orders',
                                style: GoogleFonts.inter(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(6.r)),
                            child: Text('${orders.length}',
                                style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(52.h),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_filters.length, (i) {
                            final active = _filterIndex == i;
                            return GestureDetector(
                              onTap: () => setState(() => _filterIndex = i),
                              child: AnimatedContainer(
                                duration: 200.ms,
                                margin: EdgeInsets.only(right: 8.w),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 14.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppTheme.primaryContainer
                                      : AppTheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Text(_filters[i],
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: active ? Colors.white : AppTheme.secondary,
                                      letterSpacing: 0.8,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                           return Padding(
                             padding: EdgeInsets.only(bottom: 12.h),
                             child: const _IntelligenceRail().animate().fadeIn(duration: 400.ms),
                           );
                        }
                        
                        final orderIndex = index - 1;
                        if (orders.isEmpty) {
                           return Center(
                             child: Padding(
                               padding: EdgeInsets.all(40.r),
                               child: Text("No live orders found.",
                                   style: GoogleFonts.inter(
                                       fontSize: 14.sp,
                                       color: AppTheme.secondary),
                                   maxLines: 1,
                                   overflow: TextOverflow.ellipsis),
                             ),
                           );
                        }
                        
                        if (orderIndex < orders.length) {
                          return _DynamicOrderCard(order: orders[orderIndex])
                              .animate(delay: Duration(milliseconds: 50 * orderIndex))
                              .fadeIn(duration: 400.ms);
                        }
                        return null;
                      },
                      childCount: orders.isEmpty ? 2 : orders.length + 1,
                    ),
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }
}

// ── Dynamic Order Card ─────────────────────────────────────────────────────────
class _DynamicOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _DynamicOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final tableId = order['table_id']?.toString() ?? 'T-??';
    final orderId = order['id']?.toString().substring(0, 8) ?? 'ORD-????';
    final status = order['status']?.toString().toUpperCase() ?? 'PENDING';
    final amount = order['total_amount']?.toString() ?? '0.00';
    
    List<dynamic> itemsList = [];
    if (order['items'] is List) {
      itemsList = order['items'];
    }

    return Container(
      padding: EdgeInsets.all(20.r),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        border: Border(left: BorderSide(color: const Color(0xFF94A3B8), width: 4.w)),
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TABLE $tableId · #$orderId',
                        style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.sp, color: AppTheme.secondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(status,
                        style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8.r)),
                child: Text(status,
                    style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.secondary,
                        letterSpacing: 0.8),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (itemsList.isEmpty)
             Text('No items details found',
                 style: GoogleFonts.inter(
                     fontSize: 13.sp, color: AppTheme.secondary),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis),
          ...itemsList.map((item) {
             final itemName = item is Map ? (item['name'] ?? 'Item') : item.toString();
             final qty = item is Map ? (item['quantity'] ?? 1) : 1;
             return Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  Icon(Icons.radio_button_unchecked, size: 12.r, color: AppTheme.surfaceDim),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text('$itemName × $qty', 
                        style: GoogleFonts.inter(
                            fontSize: 13.sp, color: AppTheme.secondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.surfaceContainerHigh),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text('₹$amount - VIEW DETAILS',
                  style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.secondary,
                      letterSpacing: 1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Intelligence Rail ─────────────────────────────────────────────────────────
class _IntelligenceRail extends StatelessWidget {
  const _IntelligenceRail();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: AppTheme.radiusMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KITCHEN INTELLIGENCE',
              style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: _RailStat(label: 'Avg Prep Time', value: '14m', good: true)),
              SizedBox(width: 12.w),
              Expanded(child: _RailStat(label: 'Queue Density', value: '72%', good: false)),
              SizedBox(width: 12.w),
              Expanded(child: _RailStat(label: 'Active Tables', value: '6/15', good: true)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RailStat extends StatelessWidget {
  final String label;
  final String value;
  final bool good;
  const _RailStat({required this.label, required this.value, required this.good});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, 
            style: GoogleFonts.jetBrainsMono(
                fontSize: 9.sp, color: const Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        SizedBox(height: 4.h),
        Text(value,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: good ? const Color(0xFF34D399) : const Color(0xFFFB923C)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
