import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

// ── Staff Member Model ────────────────────────────────────────────────────────
class _StaffMember {
  final String id;
  final String name;
  final String role;
  final String pin;
  final bool isActive;
  final String tenantId;

  const _StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.pin,
    required this.isActive,
    required this.tenantId,
  });

  factory _StaffMember.fromMap(Map<String, dynamic> m) => _StaffMember(
        id: m['id'] as String,
        name: m['name'] as String? ?? 'Unknown',
        role: m['role'] as String? ?? 'waiter',
        pin: m['pin'] as String? ?? '----',
        isActive: m['is_active'] as bool? ?? true,
        tenantId: m['tenant_id'] as String? ?? '',
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────
class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState
    extends ConsumerState<StaffManagementScreen> {
  List<_StaffMember> _staff = [];
  bool _isLoading = true;
  String _tenantId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _getTenantId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('tenant_id')
          .eq('id', user.id)
          .single();
      return profile['tenant_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final tid = await _getTenantId();
      if (tid == null) {
        setState(() {
          _staff = _demoStaff;
          _tenantId = 'demo';
          _isLoading = false;
        });
        return;
      }
      _tenantId = tid;
      final data = await Supabase.instance.client
          .from('staff')
          .select()
          .eq('tenant_id', tid)
          .order('name');
      setState(() {
        _staff = (data as List).map((m) => _StaffMember.fromMap(m)).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _staff = _demoStaff;
        _tenantId = 'demo';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: const Color(0xFFE2E8F0),
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 64.h,
        title: Row(
          children: [
            Text('Orderlli',
                style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryContainer)),
            SizedBox(width: 12.w),
            Container(
                width: 1.w, height: 20.h, color: const Color(0xFFE2E8F0)),
            SizedBox(width: 12.w),
            Expanded(
              child: Text('Staff',
                  style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            SizedBox(width: 8.w),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r)),
              child: Text('${_staff.length}',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryContainer)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_rounded, color: AppTheme.primaryContainer, size: 24.r),
            onPressed: () => _showStaffSheet(context, null),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryContainer))
          : _staff.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryContainer,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                    itemCount: _staff.length,
                    itemBuilder: (context, i) => _StaffCard(
                      member: _staff[i],
                      onTap: () => _showStaffSheet(context, _staff[i]),
                    )
                        .animate(
                            delay: Duration(milliseconds: 50 * i))
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1, curve: Curves.easeOut),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_outlined,
              size: 64.r,
              color: const Color(0xFFCBD5E1).withValues(alpha: 0.6)),
          SizedBox(height: 16.h),
          Text('No staff members yet',
              style: GoogleFonts.inter(
                  fontSize: 16.sp, color: const Color(0xFF94A3B8))),
          SizedBox(height: 12.h),
          ElevatedButton.icon(
            onPressed: () => _showStaffSheet(context, null),
            icon: Icon(Icons.add_rounded, size: 18.r),
            label: Text('Add First Staff', style: GoogleFonts.inter(fontSize: 14.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: Colors.white,
              minimumSize: Size(200.w, 48.h),
            ),
          ),
        ],
      ),
    );
  }

  void _showStaffSheet(BuildContext context, _StaffMember? member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StaffSheet(
        member: member,
        tenantId: _tenantId,
        onSaved: _load,
      ),
    );
  }
}

// ── Staff Card ────────────────────────────────────────────────────────────────
class _StaffCard extends StatelessWidget {
  final _StaffMember member;
  final VoidCallback onTap;

  const _StaffCard({required this.member, required this.onTap});

  Color get _roleColor => switch (member.role) {
        'owner' => AppTheme.primaryContainer,
        'manager' => const Color(0xFF3B82F6),
        _ => const Color(0xFF64748B),
      };

  String get _roleLabel => switch (member.role) {
        'owner' => 'OWNER',
        'manager' => 'MANAGER',
        _ => 'WAITER',
      };

  String get _initials {
    final parts = member.name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return member.name.substring(0, member.name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(_initials,
                        style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: _roleColor)),
                  ),
                ),
                if (member.isActive)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12.r,
                      height: 12.r,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.w),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 14.w),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(member.name,
                            style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 7.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: _roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(_roleLabel,
                            style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: _roleColor,
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text('PIN: ',
                          style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFF94A3B8))),
                      Text('●' * member.pin.length,
                          style: GoogleFonts.jetBrainsMono(
                              fontSize: 11.sp,
                              color: const Color(0xFF64748B),
                              letterSpacing: 3)),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: member.isActive
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                            member.isActive ? 'ACTIVE' : 'INACTIVE',
                            style: GoogleFonts.inter(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w700,
                                color: member.isActive
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF94A3B8),
                                letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: const Color(0xFFCBD5E1), size: 20.r),
          ],
        ),
      ),
    );
  }
}

// ── Add / Edit Staff Sheet ────────────────────────────────────────────────────
class _StaffSheet extends StatefulWidget {
  final _StaffMember? member;
  final String tenantId;
  final VoidCallback onSaved;
  const _StaffSheet(
      {this.member, required this.tenantId, required this.onSaved});

  @override
  State<_StaffSheet> createState() => _StaffSheetState();
}

class _StaffSheetState extends State<_StaffSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _pinCtrl;
  String _role = 'waiter';
  bool _active = true;
  bool _isSaving = false;

  static const _roles = ['waiter', 'manager', 'owner'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.member?.name ?? '');
    _pinCtrl = TextEditingController(text: widget.member?.pin ?? '');
    _role = widget.member?.role ?? 'waiter';
    _active = widget.member?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (name.isEmpty || pin.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final data = {
        'name': name,
        'pin': pin,
        'role': _role,
        'is_active': _active,
        'tenant_id': widget.tenantId,
      };
      if (widget.member == null) {
        await Supabase.instance.client.from('staff').insert(data);
      } else {
        await Supabase.instance.client
            .from('staff')
            .update(data)
            .eq('id', widget.member!.id);
      }
    } catch (_) {}
    if (mounted) Navigator.pop(context);
    widget.onSaved();
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _remove() async {
    if (widget.member == null) return;
    try {
      await Supabase.instance.client
          .from('staff')
          .delete()
          .eq('id', widget.member!.id);
    } catch (_) {}
    if (mounted) Navigator.pop(context);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2.r)),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      widget.member == null
                          ? 'Add Staff Member'
                          : 'Edit Staff',
                      style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A))),
                  SizedBox(height: 20.h),
                  _field('Full Name', _nameCtrl, 'e.g. Rajesh Kumar'),
                  SizedBox(height: 12.h),
                  _field('PIN (4 digits)', _pinCtrl, 'e.g. 1234',
                      type: TextInputType.number, maxLen: 4),
                  SizedBox(height: 16.h),
                  // Role
                  Text('Role',
                      style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B))),
                  SizedBox(height: 8.h),
                  Row(
                    children: _roles.map((r) {
                      final active = _role == r;
                      final color = switch (r) {
                        'owner' => AppTheme.primaryContainer,
                        'manager' => const Color(0xFF3B82F6),
                        _ => const Color(0xFF64748B),
                      };
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _role = r),
                          child: AnimatedContainer(
                            duration: 200.ms,
                            margin: EdgeInsets.only(right: 8.w),
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              color:
                                  active ? color : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Center(
                              child: Text(r.toUpperCase(),
                                  style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: active
                                          ? Colors.white
                                          : const Color(0xFF64748B))),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16.h),
                  // Active toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Active',
                          style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A))),
                      Switch(
                        value: _active,
                        onChanged: (v) => setState(() => _active = v),
                        activeThumbColor: AppTheme.primaryContainer,
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      if (widget.member != null) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _remove,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryContainer,
                              side: const BorderSide(color: AppTheme.primaryContainer),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r)),
                              padding:
                                  EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: Text('Remove',
                                style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                        SizedBox(width: 12.w),
                      ],
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryContainer,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r)),
                            padding:
                                EdgeInsets.symmetric(vertical: 14.h),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? SizedBox(
                                  width: 20.r,
                                  height: 20.r,
                                  child: const CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text('Save',
                                  style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint,
      {TextInputType? type, int? maxLen}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B))),
        SizedBox(height: 6.h),
        TextField(
          controller: ctrl,
          keyboardType: type,
          maxLength: maxLen,
          style: GoogleFonts.inter(
              fontSize: 14.sp, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: GoogleFonts.inter(
                fontSize: 14.sp, color: const Color(0xFFCBD5E1)),
            filled: true,
            fillColor: const Color(0xFFF8FAFB),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide:
                    const BorderSide(color: AppTheme.primaryContainer, width: 2)),
          ),
        ),
      ],
    );
  }
}

// ── Demo data ─────────────────────────────────────────────────────────────────
const _demoStaff = [
  _StaffMember(
      id: '1', name: 'Vikram Sharma', role: 'owner',
      pin: '1111', isActive: true, tenantId: 'demo'),
  _StaffMember(
      id: '2', name: 'Priya Mehta', role: 'manager',
      pin: '2222', isActive: true, tenantId: 'demo'),
  _StaffMember(
      id: '3', name: 'Raju Yadav', role: 'waiter',
      pin: '1234', isActive: true, tenantId: 'demo'),
  _StaffMember(
      id: '4', name: 'Ananya Singh', role: 'waiter',
      pin: '5678', isActive: false, tenantId: 'demo'),
];
