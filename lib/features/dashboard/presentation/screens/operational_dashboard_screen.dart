// lib/features/dashboard/presentation/screens/operational_dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/auth/mock_auth_provider.dart';
import '../../../tables/presentation/state/table_grid_notifier.dart';
import '../../../kitchen/presentation/state/kitchen_queue_notifier.dart';
import '../../../tables/domain/entities/restaurant_table.dart';
import '../../../orders/domain/entities/order.dart';

class OperationalDashboardScreen extends ConsumerStatefulWidget {
  const OperationalDashboardScreen({super.key});

  @override
  ConsumerState<OperationalDashboardScreen> createState() => _OperationalDashboardScreenState();
}

class _OperationalDashboardScreenState extends ConsumerState<OperationalDashboardScreen> {
  final List<String> _simulatedLogs = [];
  late Timer _logTimer;
  final ScrollController _scrollController = ScrollController();

  final List<String> _logTemplates = [
    'ticket.created -> Table T2 | Burger + Soda',
    'table.status_changed -> Table T5 (Available -> Occupied)',
    'ticket.status_changed -> Preparing Table T3',
    'ping -> branch_gateway (45ms latency)',
    'ticket.ready -> Table T4 [Cheeseburger Ready]',
    'waiter.called -> Table T1 Patio',
    r'billing.payment_received -> Table T6 ($64.50)',
    'sync.outbox -> 0 pending transactions',
  ];

  @override
  void initState() {
    super.initState();
    _simulatedLogs.add('Websocket Operational stream connected.');
    _simulatedLogs.add('Reconciliation completed: 0 delta events.');
    
    // Simulate active WebSocket traffic ticker
    _logTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      final timestamp = DateTime.now().toLocal().toString().split(' ')[1].substring(0, 8);
      final template = _logTemplates[timer.tick % _logTemplates.length];
      setState(() {
        _simulatedLogs.add('[$timestamp] $template');
        if (_simulatedLogs.length > 20) {
          _simulatedLogs.removeAt(0);
        }
      });
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _logTimer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tableGridNotifierProvider);
    final kitchenAsync = ref.watch(kitchenQueueNotifierProvider);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final appCtx = ref.watch(appContextProvider);
    final staffSession = ref.watch(staffSessionProvider);
    
    final branch = appCtx != null ? _MockBranch(appCtx.tenant.name) : null;
    final staff = staffSession;

    // Operational statistics derived from providers
    int totalTables = 0;
    int occupiedTables = 0;
    int alertTables = 0;
    List<RestaurantTable> alertList = [];
    
    tablesAsync.whenData((state) {
      final tables = state.tables;
      totalTables = tables.length;
      occupiedTables = tables.where((t) => t.status != TableStatus.available).length;
      alertList = tables.where((t) => t.status == TableStatus.needsAttention).toList();
      alertTables = alertList.length;
    });

    int preparingOrdersCount = 0;
    int readyOrdersCount = 0;
    kitchenAsync.whenData((orders) {
      preparingOrdersCount = orders.where((o) => o.status == OrderStatus.preparing || o.status == OrderStatus.sent).length;
      readyOrdersCount = orders.where((o) => o.status == OrderStatus.ready).length;
    });

    // Mock calculations for sections based on typical restaurant configurations
    double patioLoad = 0.0;
    double mainLoad = 0.0;
    double barLoad = 0.0;
    double gardenLoad = 0.0;

    tablesAsync.whenData((state) {
      final tables = state.tables;
      int patioTotal = 0, patioOcc = 0;
      int mainTotal = 0, mainOcc = 0;
      int barTotal = 0, barOcc = 0;
      int gardenTotal = 0, gardenOcc = 0;

      for (var table in tables) {
        final idNum = int.tryParse(table.id) ?? 1;
        if (idNum <= 3) {
          patioTotal++;
          if (table.status != TableStatus.available) patioOcc++;
        } else if (idNum <= 6) {
          mainTotal++;
          if (table.status != TableStatus.available) mainOcc++;
        } else if (idNum <= 8) {
          barTotal++;
          if (table.status != TableStatus.available) barOcc++;
        } else {
          gardenTotal++;
          if (table.status != TableStatus.available) gardenOcc++;
        }
      }

      patioLoad = patioTotal > 0 ? (patioOcc / patioTotal) : 0.0;
      mainLoad = mainTotal > 0 ? (mainOcc / mainTotal) : 0.0;
      barLoad = barTotal > 0 ? (barOcc / barTotal) : 0.0;
      gardenLoad = gardenTotal > 0 ? (gardenOcc / gardenTotal) : 0.0;
    });

    // Device lock shortcut
    void triggerLock() {
      // Mock lock session
      context.go('/role-select');
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              branch?.name ?? 'Operational Dashboard',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (staff != null)
              Text(
                'Shift User: ${staff.name} (${staff.role.toUpperCase()})',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary),
              ),
          ],
        ),
        actions: [
          // Connection Health Indicator
          _buildConnectionIndicator(branch),
          IconButton(
            tooltip: 'Secure Terminal Lock',
            icon: const Icon(Icons.lock_outline_rounded),
            onPressed: triggerLock,
          ),
          IconButton(
            tooltip: 'Logout Session',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ref.read(authServiceProvider).signOut();
              context.go('/role-select');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Grid of Quick Stats Metrics Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'ACTIVE TABLES',
                      value: '$occupiedTables / $totalTables',
                      subtitle: '${((totalTables > 0 ? occupiedTables / totalTables : 0) * 100).toInt()}% Occupancy',
                      color: AppColors.primary,
                      icon: Icons.table_restaurant_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'KITCHEN READY',
                      value: '$readyOrdersCount',
                      subtitle: '$preparingOrdersCount Prepping',
                      color: readyOrdersCount > 0 ? AppColors.success : AppColors.info,
                      icon: Icons.dinner_dining_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'SERVICE ALERTS',
                      value: '$alertTables',
                      subtitle: alertTables > 0 ? 'Urgent SLAs active' : 'All SLAs stable',
                      color: alertTables > 0 ? AppColors.error : Colors.grey,
                      icon: Icons.notification_important_rounded,
                      isDark: isDark,
                    ),
                  ),
                ],
              ).animate().fade(duration: 400.ms).slideY(begin: 0.05, end: 0),
              
              const SizedBox(height: 16),

              // 2. Middle Panel: SLA Alerts list (left) & Heatmap (right)
              Expanded(
                flex: 4,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SLA Alerts Column (left side)
                    Expanded(
                      flex: 3,
                      child: Card(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'SLA ALERTS (Realtime Priorities)',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                  if (alertTables > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'URGENT',
                                        style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const Divider(height: 20),
                              Expanded(
                                child: alertList.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.success.withValues(alpha: 0.7)),
                                            const SizedBox(height: 12),
                                            Text(
                                              'No active SLA alerts',
                                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Operations running within target parameters.',
                                              textAlign: TextAlign.center,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: alertList.length,
                                        itemBuilder: (context, index) {
                                          final alertTable = alertList[index];
                                          final alertCard = Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.error.withValues(alpha: 0.06),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                                                    const SizedBox(width: 12),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          'Table ${alertTable.label}: Action Required',
                                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                        Text(
                                                          'Order ready for delivery - delayed 4m',
                                                          style: theme.textTheme.bodySmall?.copyWith(
                                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    TextButton(
                                                      style: TextButton.styleFrom(
                                                        foregroundColor: AppColors.error,
                                                      ),
                                                      onPressed: () {
                                                        ref.read(tableGridNotifierProvider.notifier).updateStatus(alertTable.id, TableStatus.occupied);
                                                      },
                                                      child: const Text('Resolve'),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: AppColors.error,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                      ),
                                                      onPressed: () {
                                                        context.push('/tables/${alertTable.id}');
                                                      },
                                                      child: const Text('View'),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                           .boxShadow(
                                             begin: const BoxShadow(color: Colors.transparent),
                                             end: BoxShadow(color: AppColors.error.withValues(alpha: 0.08), blurRadius: 10),
                                             duration: 1000.ms,
                                           );
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 10.0),
                                            child: alertCard,
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Load Balance Heatmap Column (right side)
                    Expanded(
                      flex: 2,
                      child: Card(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HEATMAP GRID (Branch Load Balance)',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                              const Divider(height: 20),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildHeatmapItem('Section Patio (T1-T3)', patioLoad, AppColors.primary, theme),
                                    _buildHeatmapItem('Section Main (T4-T6)', mainLoad, AppColors.success, theme),
                                    _buildHeatmapItem('Section Bar (T7-T8)', barLoad, AppColors.warning, theme),
                                    _buildHeatmapItem('Section Garden (Other)', gardenLoad, AppColors.info, theme),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 150.ms, duration: 400.ms),

              const SizedBox(height: 12),

              // 3. Websocket Ticker Output Logger console at bottom
              Expanded(
                flex: 2,
                child: Card(
                  color: isDark ? Colors.black38 : Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'REALTIME EVENT BUS BROADCAST TICKER',
                              style: TextStyle(
                                color: Colors.white70,
                                fontFamily: 'monospace',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _simulatedLogs.length,
                            itemBuilder: (context, index) {
                              final log = _simulatedLogs[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  log,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: log.contains('error') || log.contains('outage')
                                        ? Colors.redAccent
                                        : log.contains('ready')
                                            ? Colors.greenAccent
                                            : Colors.lightBlueAccent[100],
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
              ).animate().fade(delay: 300.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.5,
                  color: Colors.grey,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapItem(String sectionName, double percentage, Color color, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sectionName,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${(percentage * 100).toInt()}% Capacity',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionIndicator(dynamic branch) {
    final status = branch?.status;
    Color color = AppColors.success;
    String label = 'SYNCED';
    bool isPulsing = true;

    if (status == null) {
      color = AppColors.error;
      label = 'UNINITIALIZED';
      isPulsing = false;
    } else if (status.name == 'busy') {
      color = AppColors.warning;
      label = 'SYNCING (4.2s)';
    } else if (status.name == 'outage') {
      color = AppColors.error;
      label = 'OFFLINE';
    }

    Widget dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );

    if (isPulsing) {
      dot = dot.animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 0.8, end: 1.2, duration: 800.ms, curve: Curves.easeInOut)
          .boxShadow(
            begin: const BoxShadow(color: Colors.transparent),
            end: BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
            duration: 800.ms,
          );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockBranch {
  final String name;
  final _MockBranchStatus status = _MockBranchStatus.synced;
  
  _MockBranch(this.name);
}

enum _MockBranchStatus { synced, busy, outage }
