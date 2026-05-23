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

class _BranchOverrideScreenState extends State<BranchOverrideScreen> {
  String _selectedBranch = 'London Soho';
  int _activeSection = 0; // 0: Hours, 1: Availability

  final List<Map<String, dynamic>> _hours = [
    {'day': 'Monday', 'baseHours': '09:00 - 22:00', 'override': '10:00 - 23:00', 'isOverridden': true},
    {'day': 'Tuesday', 'baseHours': '09:00 - 22:00', 'override': null, 'isOverridden': false},
    {'day': 'Wednesday', 'baseHours': '09:00 - 22:00', 'override': null, 'isOverridden': false},
    {'day': 'Thursday', 'baseHours': '09:00 - 22:00', 'override': '09:00 - 23:30', 'isOverridden': true},
    {'day': 'Friday', 'baseHours': '09:00 - 23:00', 'override': null, 'isOverridden': false},
    {'day': 'Saturday', 'baseHours': '09:00 - 23:00', 'override': '10:00 - 01:00', 'isOverridden': true},
    {'day': 'Sunday', 'baseHours': '10:00 - 21:00', 'override': null, 'isOverridden': false},
  ];

  final List<Map<String, dynamic>> _availability = [
    {'name': 'Vegan Burger Option', 'baseStatus': 'Available', 'override': 'Unavailable', 'isOverridden': true},
    {'name': 'Double Bacon Extra Cheddar', 'baseStatus': 'Available', 'override': null, 'isOverridden': false},
    {'name': 'Draft Lager', 'baseStatus': 'Available', 'override': null, 'isOverridden': false},
    {'name': 'Decaf Coffee', 'baseStatus': 'Available', 'override': 'Unavailable', 'isOverridden': true},
  ];

  void _toggleOverride(int index) {
    if (_activeSection == 0) {
      setState(() {
        final item = _hours[index];
        if (item['isOverridden'] as bool) {
          _hours[index]['override'] = null;
          _hours[index]['isOverridden'] = false;
        } else {
          _hours[index]['override'] = '11:00 - 23:00';
          _hours[index]['isOverridden'] = true;
        }
      });
    } else {
      setState(() {
        final item = _availability[index];
        if (item['isOverridden'] as bool) {
          _availability[index]['override'] = null;
          _availability[index]['isOverridden'] = false;
        } else {
          _availability[index]['override'] = 'Unavailable';
          _availability[index]['isOverridden'] = true;
        }
      });
    }
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
      ),
      body: Padding(
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
                      'Inheritance & Local Configuration Overrides',
                      style: GoogleFonts.inter(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      'Manage specific branch parameters. Locked parameters inherit from global settings.',
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
                    color: AppTheme.surfaceContainerLowest,
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
            
            // Tab Controls
            Row(
              children: [
                _tabButton('Operational Hours Overrides', 0),
                SizedBox(width: 12.w),
                _tabButton('Availability Overrides', 1),
              ],
            ),
            SizedBox(height: 20.h),
            
            // Workspaces Card
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppTheme.surfaceContainerHigh),
                ),
                child: ListView.separated(
                  itemCount: _activeSection == 0 ? _hours.length : _availability.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: AppTheme.surfaceContainerLow),
                  itemBuilder: (ctx, index) {
                    if (_activeSection == 0) {
                      final item = _hours[index];
                      final isOverridden = item['isOverridden'] as bool;
                      return _buildOverrideRow(
                        label: item['day'] as String,
                        baseVal: item['baseHours'] as String,
                        overrideVal: item['override'] as String?,
                        isOverridden: isOverridden,
                        onAction: () => _toggleOverride(index),
                      );
                    } else {
                      final item = _availability[index];
                      final isOverridden = item['isOverridden'] as bool;
                      return _buildOverrideRow(
                        label: item['name'] as String,
                        baseVal: item['baseStatus'] as String,
                        overrideVal: item['override'] as String?,
                        isOverridden: isOverridden,
                        onAction: () => _toggleOverride(index),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    final active = _activeSection == index;
    return GestureDetector(
      onTap: () => setState(() => _activeSection = index),
      child: AnimatedContainer(
        duration: 150.ms,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFC0272D) : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : AppTheme.secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildOverrideRow({
    required String label,
    required String baseVal,
    required String? overrideVal,
    required bool isOverridden,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(
                      isOverridden ? Icons.lock_open_rounded : Icons.lock_rounded,
                      size: 14.r,
                      color: isOverridden ? const Color(0xFFC0272D) : AppTheme.secondary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      isOverridden ? 'Explicit Override Active' : 'Inheriting from global Tenant Settings',
                      style: GoogleFonts.inter(fontSize: 11.sp, color: AppTheme.secondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Base Value', style: GoogleFonts.inter(fontSize: 10.sp, color: AppTheme.secondary)),
                Text(baseVal, style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overridden Value', style: GoogleFonts.inter(fontSize: 10.sp, color: AppTheme.secondary)),
                Text(
                  overrideVal ?? 'Inherited',
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w600,
                    color: isOverridden ? const Color(0xFFC0272D) : AppTheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: isOverridden ? const Color(0xFFC0272D) : AppTheme.secondary,
              side: BorderSide(color: isOverridden ? const Color(0xFFC0272D) : AppTheme.surfaceContainerHigh),
            ),
            child: Text(isOverridden ? 'REVERT TO INHERITED' : 'SET OVERRIDE'),
          ),
        ],
      ),
    );
  }
}
