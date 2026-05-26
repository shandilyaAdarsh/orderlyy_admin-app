import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class BranchOverrideScreen extends StatefulWidget {
  const BranchOverrideScreen({super.key});

  @override
  State<BranchOverrideScreen> createState() => _BranchOverrideScreenState();
}

class _BranchOverrideScreenState extends State<BranchOverrideScreen>
    with SingleTickerProviderStateMixin {
  String _selectedBranch = 'London Soho';
  late TabController _tabController;

  final List<Map<String, dynamic>> _hours = [
    {'day': 'Monday', 'baseHours': '09:00–22:00', 'override': '10:00–23:00', 'isOverridden': true},
    {'day': 'Tuesday', 'baseHours': '09:00–22:00', 'override': null, 'isOverridden': false},
    {'day': 'Wednesday', 'baseHours': '09:00–22:00', 'override': null, 'isOverridden': false},
    {'day': 'Thursday', 'baseHours': '09:00–22:00', 'override': '09:00–23:30', 'isOverridden': true},
    {'day': 'Friday', 'baseHours': '09:00–23:00', 'override': null, 'isOverridden': false},
    {'day': 'Saturday', 'baseHours': '09:00–23:00', 'override': '10:00–01:00', 'isOverridden': true},
    {'day': 'Sunday', 'baseHours': '10:00–21:00', 'override': null, 'isOverridden': false},
  ];

  final List<Map<String, dynamic>> _availability = [
    {'name': 'Vegan Burger Option', 'baseStatus': 'Available', 'override': 'Unavailable', 'isOverridden': true},
    {'name': 'Double Bacon Extra Cheddar', 'baseStatus': 'Available', 'override': null, 'isOverridden': false},
    {'name': 'Draft Lager', 'baseStatus': 'Available', 'override': null, 'isOverridden': false},
    {'name': 'Decaf Coffee', 'baseStatus': 'Available', 'override': 'Unavailable', 'isOverridden': true},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleOverride(int index, bool isHours) {
    setState(() {
      final list = isHours ? _hours : _availability;
      final item = list[index];
      if (item['isOverridden'] as bool) {
        list[index]['override'] = null;
        list[index]['isOverridden'] = false;
      } else {
        list[index]['override'] = isHours ? '11:00–23:00' : 'Unavailable';
        list[index]['isOverridden'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: Text(
          'Branch Override Engine',
          style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          // Branch selector moved to action button to avoid overflow
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
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
                            child: Text(b,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.sp)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBranch = val);
                  },
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryContainer,
          labelColor: AppTheme.primaryContainer,
          unselectedLabelColor: AppTheme.secondary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12.sp),
          tabs: const [
            Tab(text: 'Hours'),
            Tab(text: 'Availability'),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch info header
          Container(
            width: double.infinity,
            color: AppTheme.surfaceContainerLowest,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inheritance & Configuration Overrides',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
                ),
                Text(
                  'Branch: $_selectedBranch · Locked params inherit from global settings.',
                  style: GoogleFonts.inter(fontSize: 11.sp, color: AppTheme.secondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.surfaceContainerHigh),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverrideList(isHours: true),
                _buildOverrideList(isHours: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverrideList({required bool isHours}) {
    final list = isHours ? _hours : _availability;
    if (list.isEmpty) {
      return Center(
        child: Text('No overrides configured',
            style: GoogleFonts.inter(color: AppTheme.secondary)),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16.r),
      itemCount: list.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (ctx, index) {
        final item = list[index];
        final isOverridden = item['isOverridden'] as bool;
        final label = isHours ? item['day'] as String : item['name'] as String;
        final baseVal = isHours ? item['baseHours'] as String : item['baseStatus'] as String;
        final overrideVal = item['override'] as String?;

        return Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isOverridden
                  ? const Color(0xFFC0272D).withValues(alpha: 0.3)
                  : AppTheme.surfaceContainerHigh,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label + override badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: isOverridden
                          ? const Color(0xFFFEF2F2)
                          : AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOverridden ? Icons.lock_open_rounded : Icons.lock_rounded,
                          size: 12.r,
                          color: isOverridden ? const Color(0xFFC0272D) : AppTheme.secondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          isOverridden ? 'Override' : 'Inherited',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: isOverridden ? const Color(0xFFC0272D) : AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // Base vs override value row
              Row(
                children: [
                  Expanded(
                    child: _valueBox('Base', baseVal, AppTheme.secondary),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _valueBox(
                      'Override',
                      overrideVal ?? '—',
                      isOverridden ? const Color(0xFFC0272D) : AppTheme.secondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Action button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _toggleOverride(index, isHours),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isOverridden ? const Color(0xFFC0272D) : AppTheme.secondary,
                    side: BorderSide(
                      color: isOverridden
                          ? const Color(0xFFC0272D)
                          : AppTheme.surfaceContainerHigh,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: Text(
                    isOverridden ? 'REVERT TO INHERITED' : 'SET OVERRIDE',
                    style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn(duration: 250.ms).slideY(begin: 0.04);
      },
    );
  }

  Widget _valueBox(String label, String value, Color valueColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10.sp, color: AppTheme.secondary)),
          SizedBox(height: 2.h),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600, fontSize: 12.sp, color: valueColor),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
