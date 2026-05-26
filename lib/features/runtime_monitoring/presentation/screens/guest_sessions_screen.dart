import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class GuestSessionsScreen extends ConsumerWidget {
  const GuestSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Active Guest Sessions'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SessionCard(
            tableLabel: '4',
            guests: 3,
            sessionStart: DateTime.now().subtract(const Duration(minutes: 45)),
            lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
            status: 'Ordering',
          ),
          _SessionCard(
            tableLabel: '12',
            guests: 2,
            sessionStart: DateTime.now().subtract(const Duration(minutes: 15)),
            lastActivity: DateTime.now().subtract(const Duration(minutes: 2)),
            status: 'Browsing Menu',
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String tableLabel;
  final int guests;
  final DateTime sessionStart;
  final DateTime lastActivity;
  final String status;

  const _SessionCard({
    required this.tableLabel,
    required this.guests,
    required this.sessionStart,
    required this.lastActivity,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      color: isDark ? AppColors.darkSurface : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.table_restaurant, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Table $tableLabel',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.info),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.group, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('$guests Guests', style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 16),
                const Icon(Icons.timer, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${DateTime.now().difference(sessionStart).inMinutes}m elapsed', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Last activity: ${DateTime.now().difference(lastActivity).inMinutes}m ago',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
