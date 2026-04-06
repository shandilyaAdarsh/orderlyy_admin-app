import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifyNewOrder = true;
  bool _notifyOrderReady = true;
  bool _notifyLowStock = false;
  bool _notifyRevenue = false;
  bool _printReceipt = true;
  final _gstController = TextEditingController(text: '27AAACH0000Z1Z5');
  final _taxController = TextEditingController(text: '5.00');

  @override
  void dispose() {
    _gstController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'TableOS',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.secondary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
        children: [
          Text(
            'Settings',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your restaurant operations and system preferences.',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.secondary),
          ),
          const SizedBox(height: 28),

          // ── Notifications ───────────────────────────────────────────────────
          _sectionLabel('NOTIFICATIONS'),
          const SizedBox(height: 10),
          _card(
            children: [
              _ToggleRow(
                title: 'New Order',
                subtitle:
                    'Real-time alert for incoming dining or pickup orders',
                value: _notifyNewOrder,
                onChanged: (v) => setState(() => _notifyNewOrder = v),
              ),
              _ToggleRow(
                title: 'Order Ready',
                subtitle:
                    'Notify waitstaff when kitchen marks order as complete',
                value: _notifyOrderReady,
                onChanged: (v) => setState(() => _notifyOrderReady = v),
              ),
              _ToggleRow(
                title: 'Low Stock',
                subtitle: 'Warning when inventory items fall below threshold',
                value: _notifyLowStock,
                onChanged: (v) => setState(() => _notifyLowStock = v),
              ),
              _ToggleRow(
                title: 'Revenue Summary',
                subtitle:
                    'Daily performance digest at the end of business hours',
                value: _notifyRevenue,
                onChanged: (v) => setState(() => _notifyRevenue = v),
                divider: false,
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // ── Ordering ────────────────────────────────────────────────────────
          _sectionLabel('ORDERING'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: AppTheme.radiusMd,
            ),
            child: Column(
              children: [
                _OrderingRow(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Auto-accept',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.surfaceDim,
                  ),
                  highlight: true,
                ),
                _OrderingRow(
                  icon: Icons.volume_up_rounded,
                  label: 'Confirmation Sound',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'BEEP_01',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
                ),
                _OrderingRow(
                  icon: Icons.qr_code_2_rounded,
                  label: 'QR Auto-assign',
                  trailing: const Icon(
                    Icons.toggle_on_rounded,
                    color: AppTheme.primaryContainer,
                    size: 28,
                  ),
                ),
              ],
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // ── Display ─────────────────────────────────────────────────────────
          _sectionLabel('DISPLAY'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DisplayTile(
                  label: 'Currency',
                  value: '₹ INR',
                  mono: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DisplayTile(label: 'Language', value: 'English (US)'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DisplayTile(label: 'Timezone', value: 'IST (UTC+5:30)'),
              ),
            ],
          ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // ── Billing ─────────────────────────────────────────────────────────
          _sectionLabel('BILLING'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: AppTheme.radiusMd,
              boxShadow: AppTheme.crimsonShadowLight,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GST Number',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _gstController,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 14,
                              color: AppTheme.onSurface,
                            ),
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: AppTheme.surfaceContainerLow,
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.surfaceContainerHigh,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.surfaceContainerHigh,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.primaryContainer,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tax Rate (%)',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _taxController,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 14,
                              color: AppTheme.onSurface,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: AppTheme.surfaceContainerLow,
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.surfaceContainerHigh,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.surfaceContainerHigh,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.primaryContainer,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32, color: AppTheme.surfaceContainerLow),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.print_rounded,
                          color: AppTheme.secondary,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Print Receipt',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.onSurface,
                              ),
                            ),
                            Text(
                              'Automatically trigger thermal printer on payment',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _printReceipt,
                      onChanged: (v) => setState(() => _printReceipt = v),
                      activeTrackColor: AppTheme.primaryContainer,
                    ),
                  ],
                ),
              ],
            ),
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 40),

          // ── Danger Zone ─────────────────────────────────────────────────────
          _sectionLabel('DANGER ZONE', color: AppTheme.error),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.04),
              borderRadius: AppTheme.radiusMd,
              border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _DangerRow(
                  label: 'Reset All Orders',
                  subtitle:
                      'Permanently delete active and historical order data',
                  icon: Icons.warning_rounded,
                ),
                Divider(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  thickness: 1,
                  height: 1,
                ),
                _DangerRow(
                  label: 'Clear Menu Items',
                  subtitle:
                      'Wipe all categories, dishes, and pricing from the system',
                  icon: Icons.delete_forever_rounded,
                ),
              ],
            ),
          ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 32),

          // ── Version ─────────────────────────────────────────────────────────
          Center(
            child: Text(
              'TableOS Enterprise v4.2.0-STABLE',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: AppTheme.secondary.withValues(alpha: 0.5),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, {Color color = AppTheme.secondary}) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        boxShadow: AppTheme.crimsonShadowLight,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool divider;
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppTheme.primaryContainer,
              ),
            ],
          ),
        ),
        if (divider)
          Divider(color: AppTheme.surfaceContainerLow, thickness: 1, height: 1),
      ],
    );
  }
}

class _OrderingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final bool highlight;
  const _OrderingRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlight ? AppTheme.surface : Colors.transparent,
      borderRadius: AppTheme.radiusSm,
      child: InkWell(
        onTap: () {},
        borderRadius: AppTheme.radiusSm,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: highlight
              ? const BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: AppTheme.primaryContainer,
                      width: 3,
                    ),
                  ),
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: highlight ? AppTheme.primary : AppTheme.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _DisplayTile extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;
  const _DisplayTile({
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        border: const Border(
          bottom: BorderSide(color: AppTheme.surfaceContainerHigh, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: mono
                    ? Text(
                        value,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      )
                    : Text(
                        value,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const Icon(
                Icons.unfold_more_rounded,
                color: AppTheme.secondary,
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  const _DangerRow({
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.error,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.error.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            Icon(icon, color: AppTheme.error, size: 22),
          ],
        ),
      ),
    );
  }
}
