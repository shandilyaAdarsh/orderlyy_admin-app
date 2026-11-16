import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/dtos/floor_dto.dart';
import '../../data/dtos/table_dto.dart';
import '../../data/repositories/table_infrastructure_repository.dart';
import '../services/table_qr_file_save.dart';
import '../state/table_infrastructure_providers.dart';

class TableQrBottomSheet extends ConsumerStatefulWidget {
  const TableQrBottomSheet({
    super.key,
    required this.table,
    this.floorName,
  });

  final TableDto table;
  final String? floorName;

  @override
  ConsumerState<TableQrBottomSheet> createState() => _TableQrBottomSheetState();
}

class _TableQrBottomSheetState extends ConsumerState<TableQrBottomSheet> {
  final GlobalKey _qrKey = GlobalKey();
  bool _loading = true;
  String? _error;
  late TableDto _table;

  @override
  void initState() {
    super.initState();
    _table = widget.table;
    Future.microtask(_ensureQr);
  }

  Future<void> _ensureQr() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_table.qrUrl == null || _table.qrUrl!.isEmpty) {
        final repo = ref.read(tableInfrastructureRepositoryProvider);
        _table = await repo.generateQr(widget.table.id);
        ref.invalidate(tablesFutureProvider);
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _displayTitle {
    final floor = widget.floorName;
    final name = _table.displayName ?? _table.tableNumber;
    if (floor != null && floor.isNotEmpty) {
      return 'Table $name · $floor';
    }
    return 'Table $name';
  }

  String get _resolvedQrUrl => AppConfig.instance.normalizeCustomerQrUrl(
        _table.qrUrl,
        fallbackToken: _table.qrCodeToken ?? _table.id,
      );

  String get _shortUrl {
    final url = _resolvedQrUrl;
    if (url.isEmpty) return '';
    return url.replaceFirst(RegExp(r'^https?://'), '');
  }

  Future<void> _copyLink() async {
    final url = _resolvedQrUrl;
    if (url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied!')),
    );
  }

  Future<void> _previewCustomerMenu() async {
    final url = _resolvedQrUrl;
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open preview for $url')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open preview: $e')),
        );
      }
    }
  }

  Future<void> _downloadPng() async {
    final boundary =
        _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    if (byteData == null) return;

    final slug = _table.tableNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-');
    await saveBytesAsDownload(
      byteData.buffer.asUint8List(),
      'table-$slug-qr.png',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('QR code saved for Table ${_table.tableNumber}')),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Table?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to delete Table ${_table.tableNumber}? This cannot be undone.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppTheme.secondary)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(tablesFutureProvider.notifier).deleteTable(_table.id);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Table ${_table.tableNumber} deleted.'),
                  backgroundColor: AppTheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Delete', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl = _resolvedQrUrl;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            _displayTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 20.h),
          if (_loading)
            SizedBox(
              height: 220.h,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else if (_error != null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Text(_error!, style: const TextStyle(color: AppTheme.error)),
            )
          else if (qrUrl.isEmpty)
            ElevatedButton(
              onPressed: _ensureQr,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Generate QR'),
            )
          else ...[
            RepaintBoundary(
              key: _qrKey,
              child: QrImageView(
                data: qrUrl,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              _shortUrl,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                color: AppTheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _downloadPng,
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _previewCustomerMenu,
                    icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                    label: const Text('Preview'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      side: const BorderSide(color: AppTheme.surfaceContainerHigh),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyLink,
                    icon: const Icon(Icons.link_rounded, size: 16),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      side: const BorderSide(color: AppTheme.surfaceContainerHigh),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            TextButton.icon(
              onPressed: _confirmDelete,
              icon: Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18.r),
              label: Text(
                'Delete Table',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.error, fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String? floorNameForTable(TableDto table, List<FloorDto> floors) {
  if (table.floorId == null) return null;
  for (final f in floors) {
    if (f.id == table.floorId) return f.name;
  }
  return null;
}
