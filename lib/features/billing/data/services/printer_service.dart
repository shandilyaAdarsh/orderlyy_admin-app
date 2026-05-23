// lib/features/billing/data/services/printer_service.dart
import 'dart:io';

class PrinterException implements Exception {
  final String message;
  const PrinterException(this.message);

  @override
  String toString() => 'PrinterException: $message';
}

class LocalPrinterService {
  Future<void> printReceiptDraft(String ipAddress, String rawEscPosText) async {
    try {
      final socket = await Socket.connect(ipAddress, 9100, timeout: const Duration(seconds: 3));
      socket.write(rawEscPosText);
      await socket.flush();
      await socket.close();
    } catch (e) {
      throw PrinterException('Direct socket connection failed: $e');
    }
  }
}
