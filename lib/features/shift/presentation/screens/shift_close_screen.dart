// lib/features/shift/presentation/screens/shift_close_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

// ─── State Machine ────────────────────────────────────────────────────────────

enum ShiftCloseState { idle, validating, itemsRequiringAction, handoffInProgress, reconciling, committed, rollbackRequired }

enum UnresolvedTaskType { activeTable, unresolvedCall, preparingOrder, pendingPayment, openBill }

enum HandoffState { unassigned, pending, confirmed }

class UnresolvedTask {
  final String taskId;
  final UnresolvedTaskType type;
  final String entityLabel;
  final bool isBlocking;
  HandoffState handoff;
  String? handoffTargetName;

  UnresolvedTask({
    required this.taskId,
    required this.type,
    required this.entityLabel,
    required this.isBlocking,
    this.handoff = HandoffState.unassigned,
    this.handoffTargetName,
  });

  IconData get icon => switch (type) {
    UnresolvedTaskType.activeTable => Icons.table_restaurant_rounded,
    UnresolvedTaskType.unresolvedCall => Icons.support_agent_rounded,
    UnresolvedTaskType.preparingOrder => Icons.restaurant_rounded,
    UnresolvedTaskType.pendingPayment => Icons.account_balance_wallet_rounded,
    UnresolvedTaskType.openBill => Icons.receipt_long_rounded,
  };

  String get typeLabel => switch (type) {
    UnresolvedTaskType.activeTable => 'Active Table',
    UnresolvedTaskType.unresolvedCall => 'Waiter Call',
    UnresolvedTaskType.preparingOrder => 'Preparing Order',
    UnresolvedTaskType.pendingPayment => 'Pending Payment',
    UnresolvedTaskType.openBill => 'Open Bill',
  };
}

class AvailableStaff {
  final String staffId;
  final String name;
  final int activeTableCount;
  const AvailableStaff({required this.staffId, required this.name, required this.activeTableCount});
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final shiftCloseStateProvider = StateProvider<ShiftCloseState>((ref) => ShiftCloseState.idle);

final unresolvedTasksProvider = StateProvider<List<UnresolvedTask>>((ref) {
  return [
    UnresolvedTask(taskId: 't1', type: UnresolvedTaskType.activeTable, entityLabel: 'Table 5', isBlocking: true),
    UnresolvedTask(taskId: 't2', type: UnresolvedTaskType.activeTable, entityLabel: 'Table 12', isBlocking: true),
    UnresolvedTask(taskId: 't3', type: UnresolvedTaskType.unresolvedCall, entityLabel: 'Call — Table 7', isBlocking: false),
    UnresolvedTask(taskId: 't4', type: UnresolvedTaskType.pendingPayment, entityLabel: 'Order #1042 — Table 9', isBlocking: false),
  ];
});

final availableStaffProvider = Provider<List<AvailableStaff>>((ref) {
  return [
    const AvailableStaff(staffId: 's2', name: 'Maria K.', activeTableCount: 3),
    const AvailableStaff(staffId: 's3', name: 'David L.', activeTableCount: 2),
    const AvailableStaff(staffId: 's4', name: 'Priya M.', activeTableCount: 4),
  ];
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class ShiftCloseScreen extends ConsumerStatefulWidget {
  const ShiftCloseScreen({super.key});

  @override
  ConsumerState<ShiftCloseScreen> createState() => _ShiftCloseScreenState();
}

class _ShiftCloseScreenState extends ConsumerState<ShiftCloseScreen> {
  int _currentStep = 0;
  String? _selectedHandoffStaffId;
  String? _selectedHandoffStaffName;
  bool _canPop = false;

  @override
  Widget build(BuildContext context) {
    final closeState = ref.watch(shiftCloseStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = closeState == ShiftCloseState.committed || _canPop;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await _showCancelDialog(context);
        if (confirmed == true && context.mounted) {
          setState(() {
            _canPop = true;
          });
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          elevation: 0,
          title: const Text('End Shift', style: TextStyle(fontWeight: FontWeight.w900)),
          leading: closeState != ShiftCloseState.committed
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () async {
                    final confirmed = await _showCancelDialog(context);
                    if (confirmed == true && context.mounted) context.pop();
                  },
                )
              : null,
        ),
        body: Column(
          children: [
            _buildStepIndicator(isDark),
            Expanded(child: _buildCurrentStep(context, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    final steps = ['Checklist', 'Handoff', 'Summary', 'Confirm'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? AppColors.success : isActive ? AppColors.primary : Colors.grey.withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                              : Text('${i + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(steps[i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isActive ? AppColors.primary : Colors.grey)),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(height: 2, color: i < _currentStep ? AppColors.success : Colors.grey.withValues(alpha: 0.2), margin: const EdgeInsets.only(bottom: 20)),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, bool isDark) {
    return switch (_currentStep) {
      0 => _buildChecklistStep(context, isDark),
      1 => _buildHandoffStep(context, isDark),
      2 => _buildSummaryStep(context, isDark),
      3 => _buildConfirmStep(context, isDark),
      _ => const SizedBox.shrink(),
    };
  }

  // ── Step 1: Checklist ─────────────────────────────────────────────────────

  Widget _buildChecklistStep(BuildContext context, bool isDark) {
    final tasks = ref.watch(unresolvedTasksProvider);
    final blocking = tasks.where((t) => t.isBlocking).toList();
    final warnings = tasks.where((t) => !t.isBlocking).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (blocking.isNotEmpty) ...[
                _sectionHeader('⛔ Blocking Items', AppColors.error, 'Must be transferred before closing'),
                const SizedBox(height: 8),
                ...blocking.map((t) => _buildTaskCard(t, isDark, isBlocking: true)),
                const SizedBox(height: 16),
              ],
              if (warnings.isNotEmpty) ...[
                _sectionHeader('⚠️ Requires Acknowledgement', AppColors.warning, 'Can be handled by manager'),
                const SizedBox(height: 8),
                ...warnings.map((t) => _buildTaskCard(t, isDark, isBlocking: false)),
              ],
              if (tasks.isEmpty) ...[
                const SizedBox(height: 32),
                Center(
                  child: Column(children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),
                    const SizedBox(height: 12),
                    const Text('All clear!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('No unresolved items', style: TextStyle(color: Colors.grey[500])),
                  ]),
                ),
              ],
            ],
          ),
        ),
        _buildStepNavBar(context, isDark,
          label: 'Continue to Handoff',
          onNext: () => setState(() => _currentStep = 1),
        ),
      ],
    );
  }

  Widget _buildTaskCard(UnresolvedTask task, bool isDark, {required bool isBlocking}) {
    final color = isBlocking ? AppColors.error : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Icon(task.icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.typeLabel, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            Text(task.entityLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(isBlocking ? 'BLOCKING' : 'WARN', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
        ),
      ]),
    );
  }

  // ── Step 2: Handoff ───────────────────────────────────────────────────────

  Widget _buildHandoffStep(BuildContext context, bool isDark) {
    final staff = ref.watch(availableStaffProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionHeader('Select Handoff Recipient', AppColors.primary, 'Transfer your active tables & calls'),
              const SizedBox(height: 12),
              ...staff.map((s) => _buildStaffPickerCard(s, isDark)),
              const SizedBox(height: 16),
              if (_selectedHandoffStaffId == null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text('Select a staff member to receive your handoff items.', style: TextStyle(fontSize: 13))),
                  ]),
                ),
            ],
          ),
        ),
        _buildStepNavBar(context, isDark,
          label: 'Confirm Handoff',
          enabled: _selectedHandoffStaffId != null,
          onBack: () => setState(() => _currentStep = 0),
          onNext: () => setState(() => _currentStep = 2),
        ),
      ],
    );
  }

  Widget _buildStaffPickerCard(AvailableStaff s, bool isDark) {
    final isSelected = _selectedHandoffStaffId == s.staffId;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedHandoffStaffId = s.staffId;
          _selectedHandoffStaffName = s.name;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder), width: isSelected ? 2 : 1),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          CircleAvatar(radius: 20, backgroundColor: AppColors.primary.withValues(alpha: 0.15), child: Text(s.name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text('${s.activeTableCount} active tables', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ])),
          if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
        ]),
      ),
    );
  }

  // ── Step 3: Summary ───────────────────────────────────────────────────────

  Widget _buildSummaryStep(BuildContext context, bool isDark) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionHeader('Shift Summary', AppColors.primary, 'Review before confirming close'),
              const SizedBox(height: 16),
              _SummaryCard(isDark: isDark, items: const [
                _SummaryItem(icon: Icons.timer_rounded, label: 'Shift Duration', value: '2h 14m'),
                _SummaryItem(icon: Icons.table_restaurant_rounded, label: 'Tables Served', value: '11'),
                _SummaryItem(icon: Icons.check_circle_rounded, label: 'Orders Completed', value: '14'),
                _SummaryItem(icon: Icons.speed_rounded, label: 'SLA Compliance', value: '87%'),
                _SummaryItem(icon: Icons.support_agent_rounded, label: 'Calls Resolved', value: '3'),
              ]),
              const SizedBox(height: 16),
              if (_selectedHandoffStaffName != null) ...[
                _sectionHeader('Handoff', AppColors.success, 'Items will be transferred to:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.person_rounded, color: AppColors.success),
                    const SizedBox(width: 10),
                    Text(_selectedHandoffStaffName!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const Spacer(),
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                  ]),
                ),
              ],
            ],
          ),
        ),
        _buildStepNavBar(context, isDark,
          label: 'Proceed to Confirm',
          onBack: () => setState(() => _currentStep = 1),
          onNext: () => setState(() => _currentStep = 3),
        ),
      ],
    );
  }

  // ── Step 4: Confirm ───────────────────────────────────────────────────────

  Widget _buildConfirmStep(BuildContext context, bool isDark) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.error.withValues(alpha: 0.1)),
                    child: const Icon(Icons.logout_rounded, size: 48, color: AppColors.error),
                  ),
                  const SizedBox(height: 24),
                  const Text('Confirm Shift Close', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Text('This action is irreversible. Your shift will be closed and all items will be transferred to ${_selectedHandoffStaffName ?? 'assigned staff'}.',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.wifi_rounded, size: 14, color: AppColors.success),
                      SizedBox(width: 6),
                      Text('Connected · Sync current', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Column(children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Close My Shift', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                onPressed: () async {
                  await HapticFeedback.heavyImpact();
                  ref.read(shiftCloseStateProvider.notifier).state = ShiftCloseState.committed;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Shift closed successfully. Good work!')),
                    );
                    context.go('/tables');
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => setState(() => _currentStep = 2),
              child: const Text('Back', style: TextStyle(color: AppColors.primary)),
            ),
          ]),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, Color color, String subtitle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
      Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
    ]);
  }

  Widget _buildStepNavBar(BuildContext context, bool isDark, {required String label, required VoidCallback onNext, VoidCallback? onBack, bool enabled = true}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(children: [
        if (onBack != null) ...[
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
            style: IconButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled ? AppColors.primary : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: enabled ? () { HapticFeedback.selectionClick(); onNext(); } : null,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
      ]),
    );
  }

  Future<bool?> _showCancelDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Shift Close?'),
        content: const Text('Your shift will remain active. No changes will be saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay Here')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel Close', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final bool isDark;
  final List<_SummaryItem> items;
  const _SummaryCard({required this.isDark, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Icon(item.icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(item.label, style: const TextStyle(fontSize: 14)),
                const Spacer(),
                Text(item.value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
            ),
            if (!isLast) Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ]);
        }).toList(),
      ),
    );
  }
}

class _SummaryItem {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryItem({required this.icon, required this.label, required this.value});
}
