import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class PricingManagementScreen extends StatefulWidget {
  const PricingManagementScreen({super.key});

  @override
  State<PricingManagementScreen> createState() => _PricingManagementScreenState();
}

class _PricingManagementScreenState extends State<PricingManagementScreen> {
  String _selectedBranch = 'London Soho';
  final List<Map<String, dynamic>> _pricingItems = [
    {
      'id': 'item_burger',
      'name': 'Classic Cheeseburger',
      'category': 'Burgers',
      'basePrice': 1000.0, // in cents
      'overrides': {'London Soho': 1250.0, 'Manchester': 900.0},
    },
    {
      'id': 'item_fries',
      'name': 'Sweet Potato Fries',
      'category': 'Sides',
      'basePrice': 500.0,
      'overrides': {'London Soho': 600.0},
    },
    {
      'id': 'item_cola',
      'name': 'Craft Cola',
      'category': 'Drinks',
      'basePrice': 300.0,
      'overrides': {},
    },
    {
      'id': 'item_pie',
      'name': 'Apple Pie tart',
      'category': 'Desserts',
      'basePrice': 650.0,
      'overrides': {'Manchester': 550.0},
    },
  ];

  final List<Map<String, dynamic>> _priceHistory = [
    {
      'time': '10 mins ago',
      'actor': 'Jane Doe (Manager)',
      'item': 'Classic Cheeseburger',
      'change': 'London Soho Override updated from ₹12.00 to ₹12.50',
    },
    {
      'time': '2 hours ago',
      'actor': 'John Smith (HQ)',
      'item': 'Craft Cola',
      'change': 'Base Price updated from ₹2.50 to ₹3.00',
    },
  ];

  void _editBasePrice(int index) {
    final item = _pricingItems[index];
    final ctrl = TextEditingController(text: (item['basePrice'] / 100).toStringAsFixed(2));
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: Text(
          'Edit Base Price',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['name'] as String,
              style: GoogleFonts.inter(fontSize: 14.sp, color: AppTheme.secondary),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.jetBrainsMono(),
              decoration: InputDecoration(
                prefixText: '₹ ',
                labelText: 'Base Price (₹)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final newPrice = double.tryParse(ctrl.text);
              if (newPrice != null) {
                setState(() {
                  _pricingItems[index]['basePrice'] = newPrice * 100;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _editBranchOverride(int index) {
    final item = _pricingItems[index];
    final currentOverride = (item['overrides'] as Map)[_selectedBranch] as double?;
    final initialVal = currentOverride != null 
        ? (currentOverride / 100).toStringAsFixed(2) 
        : (item['basePrice'] / 100).toStringAsFixed(2);
        
    final ctrl = TextEditingController(text: initialVal);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: Text(
          'Branch Price Override',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item['name']} @ $_selectedBranch',
              style: GoogleFonts.inter(fontSize: 14.sp, color: AppTheme.secondary),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.jetBrainsMono(),
              decoration: InputDecoration(
                prefixText: '₹ ',
                labelText: 'Branch Price (₹)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                (_pricingItems[index]['overrides'] as Map).remove(_selectedBranch);
              });
              Navigator.pop(ctx);
            },
            child: const Text('CLEAR OVERRIDE', style: TextStyle(color: AppTheme.error)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final newPrice = double.tryParse(ctrl.text);
              if (newPrice != null) {
                setState(() {
                  (_pricingItems[index]['overrides'] as Map)[_selectedBranch] = newPrice * 100;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('APPLY', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: Text(
          'Pricing Infrastructure',
          style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Pane: Pricing List & Overrides
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.r),
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
                            'Authoritative Pricing Overrides',
                            style: GoogleFonts.inter(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          Text(
                            'Edit base pricing matrix and active branch overrides.',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: AppTheme.surfaceContainerHigh),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedBranch,
                            items: ['London Soho', 'Manchester']
                                .map((b) => DropdownMenuItem(
                                      value: b,
                                      child: Text(b, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedBranch = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  
                  // Product Table Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppTheme.surfaceContainerHigh),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pricingItems.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.surfaceContainerLow),
                      itemBuilder: (ctx, index) {
                        final item = _pricingItems[index];
                        final double baseVal = item['basePrice'] / 100;
                        final double? overrideVal = ((item['overrides'] as Map)[_selectedBranch] as double?);
                        final double currentVal = (overrideVal ?? item['basePrice']) / 100;
                        final diff = overrideVal != null ? (overrideVal - item['basePrice']) / 100 : 0.0;
                        
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      item['category'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        color: AppTheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: () => _editBasePrice(index),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Base Price',
                                        style: GoogleFonts.inter(fontSize: 10.sp, color: AppTheme.secondary),
                                      ),
                                      Text(
                                        '₹${baseVal.toStringAsFixed(2)}',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.sp,
                                          color: AppTheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: () => _editBranchOverride(index),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Branch Price ($_selectedBranch)',
                                        style: GoogleFonts.inter(fontSize: 10.sp, color: AppTheme.secondary),
                                      ),
                                      Text(
                                        '₹${currentVal.toStringAsFixed(2)}',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.sp,
                                          color: overrideVal != null 
                                              ? const Color(0xFFC0272D) 
                                              : AppTheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: overrideVal != null
                                    ? Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                        decoration: BoxDecoration(
                                          color: diff > 0 
                                              ? const Color(0xFFFEF2F2) 
                                              : const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        child: Text(
                                          diff > 0 
                                              ? '+₹${diff.toStringAsFixed(2)}' 
                                              : '-₹${diff.abs().toStringAsFixed(2)}',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold,
                                            color: diff > 0 
                                                ? const Color(0xFFC0272D) 
                                                : const Color(0xFF16A34A),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    : Text(
                                        'Inherited',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.sp,
                                          color: AppTheme.secondary.withValues(alpha: 0.6),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right Pane: Price history ledger & audit trail
          Container(
            width: 320.w,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              border: Border(left: BorderSide(color: AppTheme.surfaceContainerHigh)),
            ),
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pricing Audit Trail',
                  style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: ListView.separated(
                    itemCount: _priceHistory.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (ctx, i) {
                      final log = _priceHistory[i];
                      return Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: AppTheme.surfaceContainerHigh),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    log['actor'] as String,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.sp),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  log['time'] as String,
                                  style: GoogleFonts.inter(fontSize: 10.sp, color: AppTheme.secondary),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Item: ${log['item']}',
                              style: GoogleFonts.inter(fontSize: 11.sp, color: AppTheme.secondary),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              log['change'] as String,
                              style: GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.onSurface),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
