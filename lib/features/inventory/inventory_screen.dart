import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

enum _StockStatus { low, critical, healthy }

class _InventoryItem {
  final String category;
  final String name;
  final String quantity;
  final String unit;
  final _StockStatus status;
  final double fillRatio;
  final String fillLabel;
  const _InventoryItem({
    required this.category,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.status,
    required this.fillRatio,
    required this.fillLabel,
  });
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchController = TextEditingController();

  static const _items = [
    _InventoryItem(
      category: 'Proteins / Raw',
      name: 'Chicken Breast',
      quantity: '2.5',
      unit: 'kg',
      status: _StockStatus.low,
      fillRatio: 0.50,
      fillLabel: '50%',
    ),
    _InventoryItem(
      category: 'Mains / Signature',
      name: 'Wagyu Burger',
      quantity: '4',
      unit: 'Portions left',
      status: _StockStatus.critical,
      fillRatio: 0.20,
      fillLabel: '20%',
    ),
    _InventoryItem(
      category: 'Vegetables / Fresh',
      name: 'Roma Tomatoes',
      quantity: '12.0',
      unit: 'kg',
      status: _StockStatus.healthy,
      fillRatio: 0.85,
      fillLabel: '85%',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: const _Fab(),
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.surfaceContainerLowest,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            toolbarHeight: 72.h,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18.r,
                  backgroundColor: AppTheme.surfaceContainerHigh,
                  child: Icon(
                    Icons.person_rounded,
                    color: AppTheme.secondary,
                    size: 18.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Orderlli',
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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

          // ── Sticky header (title + tabs + banner + search) ──────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.background,
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
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
                            Text(
                              'System / Logistics',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10.sp,
                                color: AppTheme.secondary,
                                letterSpacing: 1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Inventory',
                              style: GoogleFonts.inter(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      SizedBox(
                        height: 48.h,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.add_rounded, size: 18.r),
                          label: Text(
                            'Add Item',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  // Tabs
                  TabBar(
                    controller: _tab,
                    indicatorColor: AppTheme.primary,
                    indicatorWeight: 2.h,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: AppTheme.secondary,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    dividerColor: AppTheme.surfaceContainerHigh,
                    tabs: const [
                      Tab(text: '🥩  Ingredients'),
                      Tab(text: '🍽  Menu Stock'),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  // Low stock banner
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12.r),
                        bottomRight: Radius.circular(12.r),
                      ),
                      border: Border(
                        left: BorderSide(
                          color: const Color(0xFFF59E0B),
                          width: 4.w,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: const Color(0xFFD97706),
                          size: 20.r,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            '3 items running low — Review now',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF78350F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            'View All',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFB45309),
                              letterSpacing: 1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Search
                  TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: AppTheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search inventory...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: AppTheme.secondary.withValues(alpha: 0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppTheme.secondary,
                        size: 20.r,
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLowest,
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppTheme.surfaceContainerHigh,
                          width: 2.h,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppTheme.surfaceContainerHigh,
                          width: 2.h,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppTheme.primaryContainer,
                          width: 2.h,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),

          // ── Inventory grid ──────────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 0),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, i) {
                if (i < _items.length) {
                  return _InventoryCard(item: _items[i])
                      .animate(delay: Duration(milliseconds: 80 * i))
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.15, curve: Curves.easeOut);
                }
                return null;
              }, childCount: _items.length),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisSpacing: 12.h,
                childAspectRatio: 2.4, // Adjusted for dynamic scaling
              ),
            ),
          ),

          // ── Supplier Intelligence bento ─────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
            sliver: SliverToBoxAdapter(child: const _SupplierCard()),
          ),

          // ── Inventory Log card ──────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
            sliver: SliverToBoxAdapter(child: const _InventoryLogCard()),
          ),
        ],
      ),
    );
  }
}

// ── Inventory Card ────────────────────────────────────────────────────────────
class _InventoryCard extends StatelessWidget {
  final _InventoryItem item;
  const _InventoryCard({required this.item});

  Color get _accentColor => switch (item.status) {
    _StockStatus.low => AppTheme.primaryContainer,
    _StockStatus.critical => AppTheme.error,
    _StockStatus.healthy => const Color(0xFF10B981),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        border: item.status != _StockStatus.healthy
            ? Border(
                left: BorderSide(color: AppTheme.primaryContainer, width: 3.w),
              )
            : null,
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
                    Text(
                      item.category,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.sp,
                        color: AppTheme.secondary,
                        letterSpacing: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      item.name,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _StatusBadge(status: item.status),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                item.quantity,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  item.unit,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: AppTheme.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Utilization',
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.secondary,
                  letterSpacing: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                item.fillLabel,
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  color: _accentColor,
                  letterSpacing: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999.r),
            child: LinearProgressIndicator(
              value: item.fillRatio,
              backgroundColor: AppTheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
              minHeight: 6.h,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _StockStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      _StockStatus.low => (
        'LOW STOCK',
        const Color(0xFFFEF2F2),
        const Color(0xFFB91C1C),
      ),
      _StockStatus.critical => (
        'CRITICAL',
        const Color(0xFFFEE2E2),
        const Color(0xFF7F1D1D),
      ),
      _StockStatus.healthy => (
        'HEALTHY',
        const Color(0xFFECFDF5),
        const Color(0xFF065F46),
      ),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9.sp,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Supplier Intelligence Card ────────────────────────────────────────────────
class _SupplierCard extends StatelessWidget {
  const _SupplierCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: AppTheme.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.local_shipping_rounded,
              color: AppTheme.primaryFixed,
              size: 22.r,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Projected Restock Needs',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF94A3B8),
                height: 1.5,
              ),
              children: [
                const TextSpan(
                  text:
                      'Based on current kitchen velocity, you will exhaust \'Sea Bass\' and \'Asparagus\' in the next ',
                ),
                TextSpan(
                  text: '14 hours',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Vendor: FreshCatch Ltd',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.sp,
                          color: const Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Divider(
                  color: const Color(0xFF334155),
                  thickness: 1,
                  height: 20.h,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Next Delivery',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFFCBD5E1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Tomorrow, 06:00 AM',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                backgroundColor: Colors.white,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Auto-order Essentials',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms);
  }
}

// ── Inventory Log Card ────────────────────────────────────────────────────────
class _InventoryLogCard extends StatelessWidget {
  const _InventoryLogCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      margin: EdgeInsets.only(top: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(
          color: AppTheme.surfaceContainerHigh,
          width: 1.5.w,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory Log',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Last updated by Chef Marc at 2:30 PM',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Row(
            children: [
              for (final color in [
                const Color(0xFF7C3AED),
                const Color(0xFF2563EB),
              ])
                Container(
                  width: 28.r,
                  height: 28.r,
                  margin: EdgeInsets.only(right: -8.w),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surface, width: 2.w),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 14.r,
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate(delay: 350.ms).fadeIn(duration: 400.ms);
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────
class _Fab extends StatelessWidget {
  const _Fab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {},
      backgroundColor: AppTheme.primaryContainer,
      child: Icon(Icons.inventory_2_rounded, color: Colors.white, size: 24.r),
    );
  }
}
