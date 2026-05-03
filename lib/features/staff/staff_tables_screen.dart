import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

// ── Table Status ──────────────────────────────────────────────────────────────
enum TableStatus { vacant, occupied, payment, cleaning }

class TableData {
  final String id;
  final TableStatus status;
  final int capacity;
  final String? timer;
  final String? billAmount;

  const TableData({
    required this.id,
    required this.status,
    this.capacity = 4,
    this.timer,
    this.billAmount,
  });
}

class StaffTablesScreen extends StatefulWidget {
  const StaffTablesScreen({super.key});

  @override
  State<StaffTablesScreen> createState() => _StaffTablesScreenState();
}

class _StaffTablesScreenState extends State<StaffTablesScreen> {

  static const _tables = [
    TableData(id: 'T01', status: TableStatus.vacant, capacity: 4),
    TableData(id: 'T02', status: TableStatus.occupied, capacity: 4, timer: '24:10', billAmount: '₹2,410'),
    TableData(id: 'T03', status: TableStatus.payment, capacity: 2, billAmount: '₹1,850'),
    TableData(id: 'T04', status: TableStatus.cleaning, capacity: 4),
    TableData(id: 'T05', status: TableStatus.vacant, capacity: 6),
    TableData(id: 'T06', status: TableStatus.occupied, capacity: 6, timer: '58:45', billAmount: '₹4,200'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ── Top App Bar ───────────────────────────────────────────────
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: AppTheme.surfaceContainerLowest,
                    elevation: 0,
                    toolbarHeight: 64.h,
                    shadowColor: const Color(0x149D0518),
                    surfaceTintColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    title: Row(
                      children: [
                        Text(
                          'Orderlli',
                          style: GoogleFonts.inter(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          width: 1.w,
                          height: 20.h,
                          color: AppTheme.surfaceContainerHighest,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Floor Map',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '15 TABLES',
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.secondary,
                                  letterSpacing: 1.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      Padding(
                        padding: EdgeInsets.only(right: 12.w),
                        child: CircleAvatar(
                          radius: 16.r,
                          backgroundColor: AppTheme.surfaceContainerHigh,
                          child: Icon(Icons.person_rounded, size: 18.r, color: AppTheme.secondary),
                        ),
                      ),
                    ],
                  ),

                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── Legend ──────────────────────────────────────────────
                        _buildLegend(),
                        SizedBox(height: 20.h),

                        // ── Table Grid ──────────────────────────────────────────
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220.w,
                            crossAxisSpacing: 12.w,
                            mainAxisSpacing: 12.h,
                            childAspectRatio: constraints.maxWidth > 600 ? 1.5 : 0.95,
                          ),
                          itemCount: _tables.length,
                          itemBuilder: (context, i) {
                            return _TableCard(table: _tables[i])
                                .animate(delay: Duration(milliseconds: 60 * i))
                                .fadeIn(duration: 350.ms)
                                .slideY(begin: 0.15, curve: Curves.easeOut);
                          },
                        ),
                        SizedBox(height: 16.h),

                        // ── Floor Intelligence Bento ─────────────────────────────
                        _buildFloorIntelligence(constraints),
                        SizedBox(height: 16.h),

                        // ── Add Temp Table ───────────────────────────────────────
                        _buildAddTempTable(),
                        SizedBox(height: 32.h),
                      ]),
                    ),
                  ),
                ],
              ),

              // ── FAB ─────────────────────────────────────────────────────────────
              Positioned(
                bottom: 20.h,
                right: 16.w,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 56.r,
                    height: 56.r,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.crimsonShadow,
                    ),
                    child: Icon(Icons.search_rounded, color: Colors.white, size: 26.r),
                  ),
                ).animate(delay: 400.ms).scale(
                      begin: const Offset(0, 0),
                      curve: Curves.easeOutBack,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final items = [
      (color: const Color(0xFF059669), label: 'Vacant'),
      (color: AppTheme.primaryContainer, label: 'Occupied'),
      (color: const Color(0xFFD97706), label: 'Payment'),
      (color: const Color(0xFF94A3B8), label: 'Cleaning'),
    ];
    return Wrap(
      spacing: 20.w,
      runSpacing: 8.h,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.r,
              height: 10.r,
              decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
            ),
            SizedBox(width: 6.w),
            Text(
              item.label,
              style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w500, color: AppTheme.secondary),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFloorIntelligence(BoxConstraints constraints) {
    final isSmall = constraints.maxWidth < 600;
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: AppTheme.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FLOOR INTELLIGENCE',
            style: GoogleFonts.inter(
              fontSize: 10.sp, fontWeight: FontWeight.w700,
              color: AppTheme.secondary, letterSpacing: 1.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16.h),
          if (isSmall) ...[
            Row(
              children: [
                Expanded(child: _IntelligenceStat(label: 'Turnover Rate', value: '1.2h')),
                SizedBox(width: 12.w),
                Expanded(child: _IntelligenceStat(label: 'Avg Bill', value: '₹2.8k')),
              ],
            ),
            SizedBox(height: 12.h),
            _buildTopTableCard(),
          ] else
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _IntelligenceStat(label: 'Turnover Rate', value: '1.2h')),
                      SizedBox(width: 12.w),
                      Expanded(child: _IntelligenceStat(label: 'Avg Bill', value: '₹2.8k')),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(child: _buildTopTableCard()),
              ],
            ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildTopTableCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusSm,
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('Top Table Today',
                    style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text('+12%',
                  style: GoogleFonts.jetBrainsMono(fontSize: 9.sp, fontWeight: FontWeight.w500, color: const Color(0xFF059669))),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('T02',
                      style: GoogleFonts.jetBrainsMono(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('₹18,450 Total',
                        style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppTheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('6 Sessions Served',
                        style: GoogleFonts.inter(fontSize: 10.sp, color: AppTheme.secondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddTempTable() {
    return InkWell(
      onTap: () {},
      borderRadius: AppTheme.radiusMd,
      child: Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: const Color(0x08059669),
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: const Color(0x40059669), width: 2.w, style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline_rounded, color: const Color(0xFF059669), size: 28.r),
              SizedBox(height: 4.h),
              Text(
                'ADD TEMP TABLE',
                style: GoogleFonts.inter(fontSize: 10.sp, fontWeight: FontWeight.w700, color: AppTheme.secondary, letterSpacing: 1.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: 350.ms).fadeIn(duration: 400.ms);
  }
}

// ── Table Card ────────────────────────────────────────────────────────────────
class _TableCard extends StatelessWidget {
  final TableData table;
  const _TableCard({required this.table});

  Color get _statusColor {
    return switch (table.status) {
      TableStatus.vacant   => const Color(0xFF059669),
      TableStatus.occupied => AppTheme.primaryContainer,
      TableStatus.payment  => const Color(0xFFD97706),
      TableStatus.cleaning => const Color(0xFF94A3B8),
    };
  }

  String get _statusLabel {
    return switch (table.status) {
      TableStatus.vacant   => 'VACANT',
      TableStatus.occupied => 'OCCUPIED',
      TableStatus.payment  => 'PAYMENT',
      TableStatus.cleaning => 'CLEANING',
    };
  }

  Color get _bgColor {
    return switch (table.status) {
      TableStatus.vacant   => AppTheme.surfaceContainerLowest,
      TableStatus.occupied => const Color(0x08C0272D),
      TableStatus.payment  => const Color(0x08D97706),
      TableStatus.cleaning => const Color(0x0894A3B8),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isOccupied = table.status == TableStatus.occupied;
    final isPayment  = table.status == TableStatus.payment;
    final isCleaning = table.status == TableStatus.cleaning;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: AppTheme.radiusMd,
        border: isOccupied
            ? Border.all(color: _statusColor, width: 2.w)
            : Border.all(color: _statusColor.withValues(alpha: 0.4), width: 1.w),
        boxShadow: isOccupied ? AppTheme.crimsonShadowLight : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      table.id,
                      style: GoogleFonts.inter(
                        fontSize: 22.sp, fontWeight: FontWeight.w800,
                        color: isCleaning ? AppTheme.secondary : AppTheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isOccupied)
                      Row(
                        children: [
                          Icon(Icons.timer_rounded, size: 12.r, color: _statusColor),
                          SizedBox(width: 3.w),
                          Flexible(
                            child: Text(table.timer!,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11.sp, fontWeight: FontWeight.w600, color: _statusColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      )
                    else if (isCleaning)
                      Text('Ready soon',
                          style: GoogleFonts.jetBrainsMono(fontSize: 10.sp, color: const Color(0xFF94A3B8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)
                    else
                      Row(
                        children: [
                          Icon(Icons.group_rounded, size: 12.r, color: AppTheme.secondary),
                          SizedBox(width: 3.w),
                          Text('${table.capacity}',
                              style: GoogleFonts.jetBrainsMono(fontSize: 11.sp, color: AppTheme.secondary)),
                        ],
                      ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: AppTheme.radiusFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 5.r, height: 5.r, decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
                    SizedBox(width: 4.w),
                    Text(_statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 8.sp, fontWeight: FontWeight.w800,
                          color: _statusColor, letterSpacing: 0.8,
                        )),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // Bottom row
          Divider(color: _statusColor.withValues(alpha: 0.12), thickness: 1.h),
          SizedBox(height: 8.h),
          if (isOccupied || isPayment) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPayment ? 'PENDING' : 'TOTAL BILL',
                        style: GoogleFonts.inter(fontSize: 8.sp, fontWeight: FontWeight.w800, color: AppTheme.secondary, letterSpacing: 1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        table.billAmount!,
                        style: GoogleFonts.jetBrainsMono(fontSize: 16.sp, fontWeight: FontWeight.w700, color: _statusColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 32.h,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _statusColor,
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      elevation: 0,
                    ),
                    child: Text(
                      isPayment ? 'Settle' : 'Details',
                      style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isCleaning)
            SizedBox(
              height: 32.h,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: _statusColor.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text('Mark Clean',
                    style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppTheme.secondary)),
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  minimumSize: Size.zero,
                ),
                child: Text('Assign Table',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp, fontWeight: FontWeight.w700,
                      color: AppTheme.primary, letterSpacing: 0.5,
                    )),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Floor Intelligence Stat ───────────────────────────────────────────────────
class _IntelligenceStat extends StatelessWidget {
  final String label;
  final String value;
  const _IntelligenceStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, 
              style: GoogleFonts.jetBrainsMono(fontSize: 9.sp, color: AppTheme.secondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          SizedBox(height: 4.h),
          Text(value, 
              style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.w700, color: AppTheme.primaryContainer),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

