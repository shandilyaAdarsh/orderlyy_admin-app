import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/dtos/table_dto.dart';

/// Renders QR codes to PNG bytes (no widget tree required — used for ZIP export).
class TableQrPngService {
  Future<Uint8List> renderQrPng(
    String qrUrl, {
    double logicalSize = 220,
  }) async {
    final painter = QrPainter(
      data: qrUrl,
      version: QrVersions.auto,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
    );

    final size = logicalSize * 3;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size, size), paint);
    painter.paint(canvas, Size(size, size));
    
    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to encode QR PNG');
    }
    return byteData.buffer.asUint8List();
  }

  Future<Uint8List> buildZipArchive({
    required List<TableDto> tables,
    required Map<String, String> floorNamesById,
    required Future<String> Function(TableDto table) resolveQrUrl,
  }) async {
    final archive = Archive();

    for (final table in tables) {
      final qrUrl = await resolveQrUrl(table);
      if (qrUrl.isEmpty) continue;

      final png = await renderQrPng(qrUrl);
      final floorLabel = _slugify(
        table.floorId != null
            ? (floorNamesById[table.floorId!] ?? 'floor')
            : 'floor',
      );
      final tableLabel = _slugify(table.tableNumber);
      final fileName = '$floorLabel-table-$tableLabel-qr.png';

      archive.addFile(ArchiveFile(fileName, png.length, png));
    }

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw StateError('Failed to build ZIP archive');
    }
    return Uint8List.fromList(zipBytes);
  }

  String _slugify(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
