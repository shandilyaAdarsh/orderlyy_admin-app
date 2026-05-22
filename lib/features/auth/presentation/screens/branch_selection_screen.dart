// lib/features/auth/presentation/screens/branch_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/branch.dart';
import '../state/auth_notifier.dart';

class BranchSelectionScreen extends ConsumerWidget {
  const BranchSelectionScreen({super.key});

  Color _getStatusColor(BranchStatus status) {
    switch (status) {
      case BranchStatus.open:
        return AppColors.success;
      case BranchStatus.busy:
        return AppColors.warning;
      case BranchStatus.outage:
        return AppColors.error;
    }
  }

  String _getStatusLabel(BranchStatus status) {
    switch (status) {
      case BranchStatus.open:
        return 'OPEN';
      case BranchStatus.busy:
        return 'BUSY (RUSH HOUR)';
      case BranchStatus.outage:
        return 'OUTAGE / OFFLINE';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final notifier = ref.read(authNotifierProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedOrg = authState.selectedOrg;
    if (selectedOrg == null) {
      // Safeguard redirect via GoRouter
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/org-select');
      });
      return const SizedBox.shrink();
    }

    final branches = notifier.mockBranches[selectedOrg.id] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Branch'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/org-select'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  const Icon(Icons.business_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    selectedOrg.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Link Branch Location node',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the restaurant branch workspace. Operational nodes sync state locally.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),
              
              // Branches List
              Expanded(
                child: ListView.builder(
                  itemCount: branches.length,
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    final statusColor = _getStatusColor(branch.status);
                    final isOffline = branch.status == BranchStatus.outage;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Card(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 1.5,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            if (isOffline) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${branch.name} is in outage mode. Booting into local offline mode...',
                                  ),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                            }
                            notifier.selectBranch(branch);
                            context.go('/login');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        branch.name,
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusLabel(branch.status),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.wifi_tethering_rounded, size: 16, color: statusColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Sync: ${branch.syncPercentage}',
                                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people_outline_rounded,
                                          size: 16,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Staff Active: ${branch.activeStaff}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
