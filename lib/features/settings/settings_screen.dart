import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSaving = false;
  bool _notifyNewOrder = true;
  bool _notifyOrderReady = true;
  bool _notifyLowStock = false;
  bool _notifyRevenue = false;
  bool _printReceipt = true;
  bool _autoAccept = false;
  String _confirmationSound = 'BEEP_01';
  bool _qrAutoAssign = true;
  final _gstController = TextEditingController(text: '27AAACH0000Z1Z5');
  final _taxController = TextEditingController(text: '5.00');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Try to load from Supabase if available
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await ref.read(userProfileProvider.future);
        final tenantId = profile?['tenant_id'];
        if (tenantId != null) {
          final res = await Supabase.instance.client
              .from('tenant_settings')
              .select()
              .eq('tenant_id', tenantId)
              .maybeSingle();
          if (res != null) {
            setState(() {
              _notifyNewOrder = res['notify_new_order'] ?? true;
              _notifyOrderReady = res['notify_order_ready'] ?? true;
              _notifyLowStock = res['notify_low_stock'] ?? false;
              _notifyRevenue = res['notify_revenue'] ?? false;
              _printReceipt = res['print_receipt'] ?? true;
              _autoAccept = res['auto_accept'] ?? false;
              _confirmationSound = res['confirmation_sound'] ?? 'BEEP_01';
              _qrAutoAssign = res['qr_auto_assign'] ?? true;
              _gstController.text = res['gst_number'] ?? '';
              _taxController.text = (res['tax_percentage'] ?? 5.0).toString();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final profile = await ref.read(userProfileProvider.future);
      final tenantId = profile?['tenant_id'];
      if (tenantId != null) {
        await Supabase.instance.client.from('tenant_settings').upsert({
          'tenant_id': tenantId,
          'notify_new_order': _notifyNewOrder,
          'notify_order_ready': _notifyOrderReady,
          'notify_low_stock': _notifyLowStock,
          'notify_revenue': _notifyRevenue,
          'print_receipt': _printReceipt,
          'auto_accept': _autoAccept,
          'confirmation_sound': _confirmationSound,
          'qr_auto_assign': _qrAutoAssign,
          'gst_number': _gstController.text.trim(),
          'tax_percentage': double.tryParse(_taxController.text) ?? 5.0,
          'updated_at': DateTime.now().toIso8601String(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _resetOrders() async {
    final confirmed = await _showConfirmDialog(
      'Reset All Orders',
      'This will permanently delete all order data. This action cannot be undone.',
    );
    if (!confirmed) return;

    setState(() => _isSaving = true);
    try {
      final profile = await ref.read(userProfileProvider.future);
      final tenantId = profile?['tenant_id'];
      if (tenantId != null) {
        await Supabase.instance.client
            .from('orders')
            .delete()
            .eq('tenant_id', tenantId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All orders have been reset.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset orders: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _clearMenu() async {
    final confirmed = await _showConfirmDialog(
      'Clear Menu Items',
      'This will wipe all dishes and categories. This action cannot be undone.',
    );
    if (!confirmed) return;

    setState(() => _isSaving = true);
    try {
      final profile = await ref.read(userProfileProvider.future);
      final tenantId = profile?['tenant_id'];
      if (tenantId != null) {
        await Supabase.instance.client
            .from('menu_items')
            .delete()
            .eq('tenant_id', tenantId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu items have been cleared.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear menu: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceContainerLowest,
            title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.error)),
            content: Text(message, style: GoogleFonts.inter()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('DELETE', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

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
        toolbarHeight: 64.h,
        title: Row(
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                size: 18.r,
                color: AppTheme.secondary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Orderlli',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            TextButton(
              onPressed: _saveSettings,
              child: Text('SAVE', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w800, color: AppTheme.primaryContainer)),
            ),
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: AppTheme.secondary,
              size: 24.r,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 100.h),
        children: [
          Text(
            'Settings',
            style: GoogleFonts.inter(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            'Manage your restaurant operations and system preferences.',
            style: GoogleFonts.inter(fontSize: 13.sp, color: AppTheme.secondary),
          ),
          SizedBox(height: 28.h),

          // ── Notifications ───────────────────────────────────────────────────
          _sectionLabel('NOTIFICATIONS'),
          SizedBox(height: 10.h),
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
          SizedBox(height: 24.h),

          // ── Ordering ────────────────────────────────────────────────────────
          _sectionLabel('ORDERING'),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: AppTheme.radiusMd,
            ),
            child: Column(
              children: [
                _OrderingRow(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Auto-accept',
                  subtitle: 'Automatically confirm all incoming orders',
                  trailing: Switch(
                    value: _autoAccept,
                    onChanged: (v) => setState(() => _autoAccept = v),
                    activeTrackColor: AppTheme.primaryContainer,
                  ),
                  highlight: _autoAccept,
                ),
                _OrderingRow(
                  icon: Icons.volume_up_rounded,
                  label: 'Confirmation Sound',
                  subtitle: 'Select audio cue for new notifications',
                  trailing: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      _confirmationSound,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.sp,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
                ),
                _OrderingRow(
                  icon: Icons.qr_code_2_rounded,
                  label: 'QR Auto-assign',
                  subtitle: 'Map QR codes to tables automatically',
                  trailing: Switch(
                    value: _qrAutoAssign,
                    onChanged: (v) => setState(() => _qrAutoAssign = v),
                    activeTrackColor: AppTheme.primaryContainer,
                  ),
                ),
              ],
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          SizedBox(height: 24.h),

          // ── Display ─────────────────────────────────────────────────────────
          _sectionLabel('DISPLAY'),
          SizedBox(height: 10.h),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: constraints.maxWidth > 600 ? 2.5 : 1.6,
            children: [
              _DisplayTile(
                label: 'Currency',
                value: '₹ INR',
                mono: true,
              ),
              _DisplayTile(label: 'Language', value: 'English (US)'),
              _DisplayTile(label: 'Timezone', value: 'IST (UTC+5:30)'),
            ],
          ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
          SizedBox(height: 24.h),

          // ── Billing ─────────────────────────────────────────────────────────
          _sectionLabel('BILLING'),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(20.r),
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
                              fontSize: 10.sp,
                              color: AppTheme.secondary,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          TextField(
                            controller: _gstController,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 14.sp,
                              color: AppTheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.surfaceContainerLow,
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.surfaceContainerHigh,
                                  width: 2.h,
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.surfaceContainerHigh,
                                  width: 2.h,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.primaryContainer,
                                  width: 2.h,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12.h,
                                horizontal: 12.w,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tax Rate (%)',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.sp,
                              color: AppTheme.secondary,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          TextField(
                            controller: _taxController,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 14.sp,
                              color: AppTheme.onSurface,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.surfaceContainerLow,
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.surfaceContainerHigh,
                                  width: 2.h,
                                ),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.surfaceContainerHigh,
                                  width: 2.h,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppTheme.primaryContainer,
                                  width: 2.h,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12.h,
                                horizontal: 12.w,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: 32.h, color: AppTheme.surfaceContainerLow),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.print_rounded,
                            color: AppTheme.secondary,
                            size: 24.r,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Print Receipt',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Thermal printer auto-trigger',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: AppTheme.secondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
          SizedBox(height: 40.h),

          // ── Danger Zone ─────────────────────────────────────────────────────
          _sectionLabel('DANGER ZONE', color: AppTheme.error),
          SizedBox(height: 10.h),
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
                      'Permanently delete all order data',
                  icon: Icons.warning_rounded,
                  onTap: _resetOrders,
                ),
                Divider(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  thickness: 1,
                  height: 1,
                ),
                _DangerRow(
                  label: 'Clear Menu Items',
                  subtitle:
                      'Wipe all dishes and categories',
                  icon: Icons.delete_forever_rounded,
                  onTap: _clearMenu,
                ),
              ],
            ),
          ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
          SizedBox(height: 32.h),

          // ── Version ─────────────────────────────────────────────────────────
          Center(
            child: Text(
              'Orderlli Admin v4.2.0-STABLE',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.sp,
                color: AppTheme.secondary.withValues(alpha: 0.5),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _sectionLabel(String text, {Color color = AppTheme.secondary}) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11.sp,
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppTheme.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppTheme.primaryContainer,
              ),
            ],
          ),
        ),
        if (divider)
          Divider(color: AppTheme.surfaceContainerLow, thickness: 1, height: 1.h),
      ],
    );
  }
}

class _OrderingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Widget trailing;
  final bool highlight;
  const _OrderingRow({
    required this.icon,
    required this.label,
    required this.subtitle,
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
          padding: EdgeInsets.all(14.r),
          decoration: highlight
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: AppTheme.primaryContainer,
                      width: 3.w,
                    ),
                  ),
                )
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: highlight ? AppTheme.primary : AppTheme.secondary,
                      size: 20.r,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: AppTheme.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: AppTheme.radiusMd,
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceContainerHigh, width: 2.h),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondary,
              letterSpacing: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: mono
                    ? Text(
                        value,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13.sp, // Scaled down for mobile grids
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        value,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp, // Scaled down for mobile grids
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
              ),
              Icon(
                Icons.unfold_more_rounded,
                color: AppTheme.secondary,
                size: 16.r,
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
  final VoidCallback onTap;
  const _DangerRow({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: AppTheme.error.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Icon(icon, color: AppTheme.error, size: 22.r),
          ],
        ),
      ),
    );
  }
}
