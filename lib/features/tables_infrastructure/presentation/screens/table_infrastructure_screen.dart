import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:orderlli_admin/core/theme/app_theme.dart';
import 'package:orderlli_admin/features/tables_infrastructure/data/dtos/table_dto.dart';
import 'package:orderlli_admin/features/tables_infrastructure/data/repositories/table_infrastructure_repository.dart';
import 'package:orderlli_admin/features/tables_infrastructure/presentation/state/table_infrastructure_providers.dart';

class TableInfrastructureScreen extends ConsumerWidget {
  const TableInfrastructureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesFutureProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        elevation: 0,
        title: Text(
          'Table Infrastructure',
          style: GoogleFonts.inter(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Table',
            onPressed: () {
              // TODO: Implement Create Table Dialog
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(tablesFutureProvider),
          ),
        ],
      ),
      body: tablesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error loading tables: $err',
            style: GoogleFonts.inter(color: AppTheme.error),
          ),
        ),
        data: (tables) {
          if (tables.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.table_restaurant_rounded,
                      size: 64.r, color: AppTheme.secondary.withValues(alpha: 0.4)),
                  SizedBox(height: 16.h),
                  Text('No tables configured.',
                      style: GoogleFonts.inter(color: AppTheme.secondary, fontSize: 14.sp)),
                  SizedBox(height: 8.h),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Table'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryContainer,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.r),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              return _TableCard(
                table: table,
                onQrTap: () => _showQrDialog(context, ref, table),
              );
            },
          );
        },
      ),
    );
  }

  void _showQrDialog(BuildContext context, WidgetRef ref, TableDto table) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: Text(
          'QR Code: Table ${table.label}',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceContainerHigh),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_2, size: 150, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan to access the digital menu for this table.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.secondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                'Token: ${table.qrCodeToken}',
                style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final repo = ref.read(tableInfrastructureRepositoryProvider);
                await repo.rotateQrCode(table.id);
                ref.invalidate(tablesFutureProvider);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              } catch (e) {
                // ignore for now
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Rotate QR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final TableDto table;
  final VoidCallback onQrTap;

  const _TableCard({required this.table, required this.onQrTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.surfaceContainerHigh),
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      child: Row(
        children: [
          // Table number badge
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text(
                table.label,
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryContainer,
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Table ${table.label}',
                  style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Capacity: ${table.capacity} · Section: ${table.sectionId}',
                  style: GoogleFonts.inter(fontSize: 12.sp, color: AppTheme.secondary),
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: table.isActive
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    table.isActive ? 'Active' : 'Inactive',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: table.isActive ? const Color(0xFF10B981) : AppTheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            icon: Icon(Icons.qr_code_rounded, color: AppTheme.primaryContainer, size: 22.r),
            tooltip: 'View / Rotate QR',
            onPressed: onQrTap,
          ),
          IconButton(
            icon: Icon(Icons.edit_rounded, color: AppTheme.secondary, size: 20.r),
            tooltip: 'Edit Config',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
