import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../runtime/occ_conflict_resolver.dart';
import '../../domain/entities/menu_snapshot.dart';
import '../../../../shared/models/money.dart';

class OccConflictScreen extends StatefulWidget {
  const OccConflictScreen({super.key});

  @override
  State<OccConflictScreen> createState() => _OccConflictScreenState();
}

class _OccConflictScreenState extends State<OccConflictScreen> {
  late MenuSnapshot _baseSnapshot;
  late MenuSnapshot _localOptimistic;
  late MenuSnapshot _serverAuthoritative;
  OccConflictResult<MenuSnapshot>? _mergeResult;

  @override
  void initState() {
    super.initState();
    _resetSimState();
  }

  void _resetSimState() {
    _baseSnapshot = const MenuSnapshot(
      categories: [
        MenuCategory(id: 'cat_1', name: 'Burgers', sortOrder: 1),
      ],
      items: [
        MenuItem(
          id: 'item_burger',
          categoryId: 'cat_1',
          name: 'Classic Cheeseburger',
          description: 'Base Description',
          price: Money(amountInCents: 1000),
          isAvailable: true,
          modifierGroupIds: [],
        ),
      ],
      modifierGroups: [],
      taxConfig: TaxConfig(vatRate: 0.10, serviceChargeRate: 0.05),
      snapshotVersion: 'v2',
    );

    // Local changes (e.g. Price updated to ₹12.50)
    _localOptimistic = _baseSnapshot.copyWith(
      items: [
        _baseSnapshot.items[0].copyWith(
          price: const Money(amountInCents: 1250),
        ),
      ],
    );

    // Server has concurrent changes (e.g. Availability toggled off by another manager)
    _serverAuthoritative = _baseSnapshot.copyWith(
      items: [
        _baseSnapshot.items[0].copyWith(
          isAvailable: false,
        ),
      ],
      snapshotVersion: 'v3',
    );
    _mergeResult = null;
  }

  void _runConflictResolution() {
    final resolver = OccConflictResolver(Talker());
    final result = resolver.resolveSnapshotConflict(
      localOptimistic: _localOptimistic,
      serverAuthoritative: _serverAuthoritative,
      expectedBaseVersion: 'v2',
      baseSnapshot: _baseSnapshot,
    );
    setState(() {
      _mergeResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final burgerBase = _baseSnapshot.items[0];
    final burgerLocal = _localOptimistic.items[0];
    final burgerServer = _serverAuthoritative.items[0];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: Text(
          'OCC Conflict Resolution Workspace',
          style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner/Header
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Color(0xFFC0272D), size: 28),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ Concurrency Mutation Mismatch Detected',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7F1D1D),
                          ),
                        ),
                        Text(
                          'Another administrator has modified this configuration. Review differences below to prevent data overwrites.',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            
            // Diff Side-by-Side Cards
            Row(
              children: [
                _diffCard(
                  title: 'Your Workspace Edits (Optimistic)',
                  version: 'v2 (Modified locally)',
                  price: '₹${(burgerLocal.price.amountInCents / 100).toStringAsFixed(2)}',
                  availability: burgerLocal.isAvailable ? 'Available' : 'Unavailable',
                  borderColor: const Color(0xFFCBD5E1),
                ),
                SizedBox(width: 16.w),
                _diffCard(
                  title: 'Current Server State (Authoritative)',
                  version: 'v3 (Modified in other session)',
                  price: '₹${(burgerServer.price.amountInCents / 100).toStringAsFixed(2)}',
                  availability: burgerServer.isAvailable ? 'Available' : 'Unavailable',
                  borderColor: const Color(0xFFFCA5A5),
                  isConflict: true,
                ),
              ],
            ),
            SizedBox(height: 24.h),
            
            // Controls
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _runConflictResolution,
                  icon: const Icon(Icons.merge_type_rounded, color: Colors.white),
                  label: const Text('AUTO-MERGE CHANGES (3-WAY MERGE)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0272D),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                  ),
                ),
                SizedBox(width: 12.w),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _mergeResult = OccConflictResult(
                        hasConflict: false,
                        reconciledState: _serverAuthoritative,
                      );
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                  ),
                  child: const Text('KEEP SERVER VERSION (ROLLBACK)'),
                ),
                SizedBox(width: 12.w),
                OutlinedButton(
                  onPressed: _resetSimState,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                  ),
                  child: const Text('RESET SIMULATOR'),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            
            // Merge Result Section
            if (_mergeResult != null) ...[
              Text(
                'Reconciliation Result',
                style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ).animate().fadeIn(),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
                        SizedBox(width: 12.w),
                        Text(
                          'Merged Configuration Committed Safely',
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF14532D),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Reconciliation details:',
                      style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF15803D), fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '• Item Price merged from Local: ₹${(_mergeResult!.reconciledState.items[0].price.amountInCents / 100).toStringAsFixed(2)}',
                      style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF166534)),
                    ),
                    Text(
                      '• Item Availability merged from Server: ${_mergeResult!.reconciledState.items[0].isAvailable ? 'Available' : 'Unavailable'}',
                      style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF166534)),
                    ),
                    Text(
                      '• Committed Version token set to: ${_mergeResult!.reconciledState.snapshotVersion}',
                      style: GoogleFonts.inter(fontSize: 13.sp, color: const Color(0xFF166534)),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.1, duration: 200.ms),
            ],
          ],
        ),
      ),
    );
  }

  Widget _diffCard({
    required String title,
    required String version,
    required String price,
    required String availability,
    required Color borderColor,
    bool isConflict = false,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15.sp, color: isConflict ? const Color(0xFFC0272D) : AppTheme.onSurface),
            ),
            SizedBox(height: 4.h),
            Text(
              'Version: $version',
              style: GoogleFonts.jetBrainsMono(fontSize: 11.sp, color: AppTheme.secondary),
            ),
            SizedBox(height: 16.h),
            _paramRow('Product Price', price),
            const Divider(color: Color(0xFFE2E8F0)),
            _paramRow('Availability State', availability),
          ],
        ),
      ),
    );
  }

  Widget _paramRow(String label, String val) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppTheme.secondary)),
          Text(val, style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

