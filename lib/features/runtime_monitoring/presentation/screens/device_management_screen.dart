import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class DeviceManagementScreen extends ConsumerWidget {
  const DeviceManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Device Management'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DeviceCard(
            deviceName: 'Kitchen Display (KDS 1)',
            deviceType: 'Tablet',
            appVersion: 'v1.4.2',
            lastSync: DateTime.now().subtract(const Duration(seconds: 12)),
            status: 'Online',
          ),
          _DeviceCard(
            deviceName: 'Main POS Terminal',
            deviceType: 'Desktop',
            appVersion: 'v1.4.2',
            lastSync: DateTime.now().subtract(const Duration(minutes: 2)),
            status: 'Online',
          ),
          _DeviceCard(
            deviceName: 'Waiter Tablet (John)',
            deviceType: 'Tablet',
            appVersion: 'v1.4.0',
            lastSync: DateTime.now().subtract(const Duration(hours: 4)),
            status: 'Offline',
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final String deviceName;
  final String deviceType;
  final String appVersion;
  final DateTime lastSync;
  final String status;

  const _DeviceCard({
    required this.deviceName,
    required this.deviceType,
    required this.appVersion,
    required this.lastSync,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final isOnline = status == 'Online';
    final statusColor = isOnline ? AppColors.success : Colors.grey;

    return Card(
      color: isDark ? AppColors.darkSurface : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          deviceType == 'Tablet' ? Icons.tablet_mac : Icons.desktop_windows,
          size: 40,
          color: isOnline ? AppColors.primary : Colors.grey,
        ),
        title: Text(deviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('App Version: $appVersion'),
            const SizedBox(height: 2),
            Text('Last sync: ${DateTime.now().difference(lastSync).inMinutes}m ago'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 4),
            Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
