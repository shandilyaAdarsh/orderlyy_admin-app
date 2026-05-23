import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  String _selectedScope = 'ALL';
  String _selectedBranch = 'ALL';

  final List<Map<String, dynamic>> _auditLogs = [
    {
      'timestamp': '2026-05-24 03:10:15',
      'actor': 'Jane Doe',
      'role': 'Store Manager',
      'action': 'Toggled Availability',
      'details': "Changed Classic Cheeseburger state to 'Unavailable' at London Soho.",
      'scope': 'AVAILABILITY',
      'branch': 'London Soho',
    },
    {
      'timestamp': '2026-05-24 02:40:44',
      'actor': 'John Smith',
      'role': 'HQ Administrator',
      'action': 'Pricing Override Applied',
      'details': 'Set London Soho price override for Sweet Potato Fries to ₹6.00 (Base: ₹5.00).',
      'scope': 'PRICING',
      'branch': 'London Soho',
    },
    {
      'timestamp': '2026-05-23 23:15:00',
      'actor': 'System Job',
      'role': 'Scheduler',
      'action': 'Tax Code Auto-Applied',
      'details': "Updated VAT rules to match new legal guidelines (Standard category set to 20%).",
      'scope': 'TAXES',
      'branch': 'System Wide',
    },
    {
      'timestamp': '2026-05-23 20:05:12',
      'actor': 'Sarah Connor',
      'role': 'Branch Manager',
      'action': 'Staff Member Added',
      'details': "Invited chef 'David Green' with role 'KDS Operator'.",
      'scope': 'STAFF',
      'branch': 'Manchester',
    },
  ];

  List<Map<String, dynamic>> get _filteredLogs {
    return _auditLogs.where((log) {
      final matchesScope = _selectedScope == 'ALL' || log['scope'] == _selectedScope;
      final matchesBranch = _selectedBranch == 'ALL' || log['branch'] == _selectedBranch;
      return matchesScope && matchesBranch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: Text(
          'Operational Ledger Logs',
          style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Immutable Configuration Audit History',
                      style: GoogleFonts.inter(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      'Operational ledger listing who, when, and what changed in the system.',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
                
                // Filters Row
                Row(
                  children: [
                    _filterDropdown(
                      label: 'Action Scope',
                      value: _selectedScope,
                      items: ['ALL', 'AVAILABILITY', 'PRICING', 'TAXES', 'STAFF'],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedScope = val);
                      },
                    ),
                    SizedBox(width: 12.w),
                    _filterDropdown(
                      label: 'Target Branch',
                      value: _selectedBranch,
                      items: ['ALL', 'London Soho', 'Manchester', 'System Wide'],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBranch = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24.h),
            
            // Ledger Timeline Card List
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppTheme.surfaceContainerHigh),
                ),
                child: _filteredLogs.isEmpty
                    ? Center(
                        child: Text(
                          'No audit logs match current filters.',
                          style: GoogleFonts.inter(color: AppTheme.secondary),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(20.r),
                        itemCount: _filteredLogs.length,
                        separatorBuilder: (_, __) => SizedBox(height: 16.h),
                        itemBuilder: (ctx, index) {
                          final log = _filteredLogs[index];
                          final String scope = log['scope'] as String;
                          Color badgeColor = const Color(0xFF64748B);
                          if (scope == 'AVAILABILITY') badgeColor = const Color(0xFF16A34A);
                          if (scope == 'PRICING') badgeColor = const Color(0xFFC0272D);
                          if (scope == 'TAXES') badgeColor = const Color(0xFFF59E0B);
                          if (scope == 'STAFF') badgeColor = const Color(0xFF7C3AED);

                          return Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: AppTheme.surfaceContainerHigh),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Icon Badge
                                Container(
                                  width: 42.r,
                                  height: 42.r,
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    scope == 'PRICING' 
                                        ? Icons.monetization_on_outlined 
                                        : scope == 'TAXES' 
                                            ? Icons.percent_rounded 
                                            : scope == 'STAFF' 
                                                ? Icons.badge_outlined 
                                                : Icons.restaurant_menu_rounded,
                                    color: badgeColor,
                                    size: 20.r,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            log['action'] as String,
                                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15.sp),
                                          ),
                                          Text(
                                            log['timestamp'] as String,
                                            style: GoogleFonts.jetBrainsMono(fontSize: 12.sp, color: AppTheme.secondary),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        log['details'] as String,
                                        style: GoogleFonts.inter(fontSize: 13.sp, color: AppTheme.onSurface),
                                      ),
                                      SizedBox(height: 8.h),
                                      Row(
                                        children: [
                                          Text(
                                            'Actor: ${log['actor']} (${log['role']})',
                                            style: GoogleFonts.inter(fontSize: 11.sp, color: AppTheme.secondary, fontWeight: FontWeight.w500),
                                          ),
                                          SizedBox(width: 12.w),
                                          Container(
                                            width: 4.r,
                                            height: 4.r,
                                            decoration: const BoxDecoration(color: Color(0xFFCBD5E1), shape: BoxShape.circle),
                                          ),
                                          SizedBox(width: 12.w),
                                          Text(
                                            'Branch: ${log['branch']}',
                                            style: GoogleFonts.inter(fontSize: 11.sp, color: AppTheme.secondary, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().slideY(begin: 0.1, duration: 250.ms);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items
                  .map((it) => DropdownMenuItem(
                        value: it,
                        child: Text(it, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.sp)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
