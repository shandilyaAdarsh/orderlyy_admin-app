import 'package:flutter_test/flutter_test.dart';
import 'package:orderlli_admin/core/config/app_config.dart';
import 'package:orderlli_admin/core/config/environment.dart';
import 'package:orderlli_admin/features/tables/models/table_model.dart';
import 'package:orderlli_admin/features/tables_infrastructure/data/dtos/table_dto.dart';
import 'package:orderlli_admin/features/tables_infrastructure/presentation/services/qr_export_service.dart';

void main() {
  group('Customer Menu QR Production URL Connection Tests', () {
    const testToken = 'TEST_TOKEN';
    const expectedProductionUrl = 'https://table-os-1.onrender.com/t/$testToken';

    setUp(() {
      // Initialize with Production Environment
      AppConfig.initialize(
        environment: Environment.prod,
        customerAppUrl: 'https://table-os-1.onrender.com',
      );
    });

    test('1. Production customer URL configuration in AppConfig', () {
      expect(AppConfig.instance.customerAppUrl, equals('https://table-os-1.onrender.com'));
      expect(AppConfig.instance.customerAppUrl.contains('localhost'), isFalse);
      expect(AppConfig.instance.customerAppUrl.endsWith('/'), isFalse);
    });

    test('2. QR URL construction for known test token TEST_TOKEN', () {
      final generatedUrl = AppConfig.instance.buildCustomerQrUrl(testToken);
      expect(generatedUrl, equals(expectedProductionUrl));
      expect(generatedUrl, equals('https://table-os-1.onrender.com/t/TEST_TOKEN'));
      expect(generatedUrl.contains('localhost'), isFalse);
    });

    test('3. Trailing slash normalization in AppConfig', () {
      AppConfig.initialize(
        environment: Environment.prod,
        customerAppUrl: 'https://table-os-1.onrender.com///',
      );
      expect(AppConfig.instance.customerAppUrl, equals('https://table-os-1.onrender.com'));
      expect(AppConfig.instance.buildCustomerQrUrl(testToken), equals(expectedProductionUrl));
    });

    test('4. Existing token preservation and localhost normalization', () {
      // Legacy localhost URL from dev database
      final normalizedFromLocalhost = AppConfig.instance.normalizeCustomerQrUrl('http://localhost:5173/t/$testToken');
      expect(normalizedFromLocalhost, equals(expectedProductionUrl));

      // Android emulator localhost URL
      final normalizedFromEmulator = AppConfig.instance.normalizeCustomerQrUrl('http://10.0.2.2:5173/t/$testToken');
      expect(normalizedFromEmulator, equals(expectedProductionUrl));

      // Stale production domain
      final normalizedFromOldDomain = AppConfig.instance.normalizeCustomerQrUrl('https://app.orderlyy.com/t/$testToken');
      expect(normalizedFromOldDomain, equals(expectedProductionUrl));

      // Backend API domain
      final normalizedFromBackendUrl = AppConfig.instance.normalizeCustomerQrUrl('https://table-os.onrender.com/t/$testToken');
      expect(normalizedFromBackendUrl, equals(expectedProductionUrl));

      // Bare token
      final normalizedFromBareToken = AppConfig.instance.normalizeCustomerQrUrl(testToken);
      expect(normalizedFromBareToken, equals(expectedProductionUrl));
    });

    test('5. RestaurantTable model QR URL construction and normalization', () {
      final table = RestaurantTable.fromJson({
        'id': '00000000-0000-0000-0000-000000000001',
        'tenant_id': 'tenant-123',
        'branch_id': 'branch-456',
        'table_number': '1',
        'qr_token': testToken,
        'qr_url': 'http://localhost:5173/t/$testToken',
      });

      expect(table.qrUrl, equals(expectedProductionUrl));
      expect(table.qrUrl.contains('localhost'), isFalse);
    });

    test('6. TableDto resolvedQrUrl construction and normalization', () {
      final tableDto = TableDto(
        id: 'table-uuid-1',
        tenantId: 'tenant-123',
        branchId: 'branch-456',
        tableNumber: '5',
        capacity: 4,
        qrCodeToken: testToken,
        qrUrl: 'http://localhost:5173/t/$testToken',
        isActive: true,
      );

      expect(tableDto.resolvedQrUrl, equals(expectedProductionUrl));
      expect(tableDto.resolvedQrUrl.contains('localhost'), isFalse);
    });

    test('7. QRExportService batch PDF generation uses production URL', () async {
      final service = QRExportService();
      final tableDto = TableDto(
        id: 'table-uuid-1',
        tenantId: 'tenant-123',
        branchId: 'branch-456',
        tableNumber: '1',
        capacity: 2,
        isActive: true,
      );

      final pdfBytes = await service.generateBatchQrSheet(
        [tableDto],
        'Test Branch',
        getQrToken: (id) async => testToken,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));
    });

    test('8. QRExportService single PDF generation normalizes legacy URLs', () async {
      final service = QRExportService();
      final tableDto = TableDto(
        id: 'table-uuid-1',
        tenantId: 'tenant-123',
        branchId: 'branch-456',
        tableNumber: '1',
        capacity: 2,
        qrCodeToken: testToken,
        isActive: true,
      );

      final pdfBytes = await service.generateSingleQrPdf(
        tableDto,
        'Test Branch',
        'http://localhost:5173/t/$testToken',
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100));
    });

    test('9. No localhost in production QR output', () {
      final builtUrl = AppConfig.instance.buildCustomerQrUrl(testToken);
      final normalizedUrl = AppConfig.instance.normalizeCustomerQrUrl('http://127.0.0.1:5173/t/$testToken');

      expect(builtUrl.contains('localhost'), isFalse);
      expect(builtUrl.contains('127.0.0.1'), isFalse);
      expect(normalizedUrl.contains('localhost'), isFalse);
      expect(normalizedUrl.contains('127.0.0.1'), isFalse);
    });
  });
}
