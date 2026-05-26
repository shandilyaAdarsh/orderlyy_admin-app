import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/data/dtos/staff_dto.dart';
import '../../core/providers/staff_providers.dart';
import '../../core/auth/mock_auth_provider.dart';
import '../../core/utils/uuid.dart';
import '../../core/theme/app_theme.dart';

// ── Screen ────────────────────────────────────────────────────────────────────
class StaffManagementScreen extends ConsumerWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffStreamProvider);

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
            Text(
              'Orderlli',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryContainer,
              ),
            ),
            SizedBox(width: 12.w),
            Container(width: 1.w, height: 20.h, color: const Color(0xFFE2E8F0)),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Staff',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8.w),
            staffAsync.maybeWhen(
              data: (staff) => Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${staff.length}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryContainer,
                  ),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.person_add_rounded,
              color: AppTheme.primaryContainer,
              size: 24.r,
            ),
            onPressed: () => _showStaffSheet(context, ref, null),
          ),
        ],
      ),
      body: staffAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryContainer),
        ),
        error: (err, _) => Center(
          child: Text(
            'Failed to load staff: $err',
            style: GoogleFonts.inter(color: AppTheme.error),
          ),
        ),
        data: (staff) => staff.isEmpty
            ? _buildEmpty(context, ref)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(staffStreamProvider),
                color: AppTheme.primaryContainer,
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                  itemCount: staff.length,
                  itemBuilder: (context, i) =>
                      _StaffCard(
                            member: staff[i],
                            onTap: () =>
                                _showStaffSheet(context, ref, staff[i]),
                          )
                          .animate(delay: Duration(milliseconds: 50 * i))
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.1, curve: Curves.easeOut),
                ),
              ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.group_outlined,
            size: 64.r,
            color: const Color(0xFFCBD5E1).withValues(alpha: 0.6),
          ),
          SizedBox(height: 16.h),
          Text(
            'No staff members yet',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 12.h),
          ElevatedButton.icon(
            onPressed: () => _showStaffSheet(context, ref, null),
            icon: Icon(Icons.add_rounded, size: 18.r),
            label: Text(
              'Add First Staff',
              style: GoogleFonts.inter(fontSize: 14.sp),
            ),
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

  void _showStaffSheet(BuildContext context, WidgetRef ref, StaffDto? member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StaffSheet(member: member),
    );
  }
}

// ── Staff Card ────────────────────────────────────────────────────────────────
class _StaffCard extends StatelessWidget {
  final StaffDto member;
  final VoidCallback onTap;

  const _StaffCard({required this.member, required this.onTap});

  Color get _roleColor => switch (member.role) {
    StaffRole.owner => AppTheme.primaryContainer,
    StaffRole.manager => const Color(0xFF3B82F6),
    StaffRole.waiter => const Color(0xFF64748B),
  };

  String get _initials {
    final parts = member.name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return member.name
        .substring(0, member.name.length >= 2 ? 2 : 1)
        .toUpperCase();
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
                    child: Text(
                      _initials,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: _roleColor,
                      ),
                    ),
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
                        child: Text(
                          member.name,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: _roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          member.role.displayLabel,
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: _roleColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        'PIN: ',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        '●' * member.pin.length,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11.sp,
                          color: const Color(0xFF64748B),
                          letterSpacing: 3,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.h,
                        ),
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
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFFCBD5E1),
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add / Edit Staff Sheet ────────────────────────────────────────────────────
class _StaffSheet extends ConsumerStatefulWidget {
  final StaffDto? member;
  const _StaffSheet({this.member});

  @override
  ConsumerState<_StaffSheet> createState() => _StaffSheetState();
}

class _StaffSheetState extends ConsumerState<_StaffSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _pinCtrl;
  StaffRole _role = StaffRole.waiter;
  bool _active = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.member?.name ?? '');
    _pinCtrl = TextEditingController(text: widget.member?.pin ?? '');
    _role = widget.member?.role ?? StaffRole.waiter;
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
      final appContext = ref.read(appContextProvider);
      final tenantId = appContext?.tenant.id ?? '';
      if (tenantId.isEmpty) {
        throw Exception('Tenant context is not yet loaded.');
      }
      if (widget.member == null) {
        // Create
        final newStaff = StaffDto(
          id: UuidGenerator.generateRuntimeId(prefix: 'staff'),
          tenantId: tenantId,
          name: name,
          role: _role,
          pin: pin,
          isActive: _active,
        );
        await ref.read(createStaffProvider)(newStaff);
      } else {
        // Update
        final updated = widget.member!.copyWith(
          name: name,
          role: _role,
          pin: pin,
          isActive: _active,
        );
        await ref.read(updateStaffProvider)(updated);
      }
    } catch (_) {
      // Errors are surfaced via the stream; silently continue
    }
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  Future<void> _remove() async {
    if (widget.member == null) return;
    try {
      await ref.read(deleteStaffProvider)(widget.member!.id);
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.member == null ? 'Add Staff Member' : 'Edit Staff',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _field('Full Name', _nameCtrl, 'e.g. Rajesh Kumar'),
                  SizedBox(height: 12.h),
                  _field(
                    'PIN (4 digits)',
                    _pinCtrl,
                    'e.g. 1234',
                    type: TextInputType.number,
                    maxLen: 4,
                  ),
                  SizedBox(height: 16.h),
                  // Role
                  Text(
                    'Role',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: StaffRole.values.map((r) {
                      final active = _role == r;
                      final color = switch (r) {
                        StaffRole.owner => AppTheme.primaryContainer,
                        StaffRole.manager => const Color(0xFF3B82F6),
                        StaffRole.waiter => const Color(0xFF64748B),
                      };
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _role = r),
                          child: AnimatedContainer(
                            duration: 200.ms,
                            margin: EdgeInsets.only(right: 8.w),
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              color: active ? color : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Center(
                              child: Text(
                                r.displayLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                              ),
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
                      Text(
                        'Active',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
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
                              side: const BorderSide(
                                color: AppTheme.primaryContainer,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: Text(
                              'Remove',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? SizedBox(
                                  width: 20.r,
                                  height: 20.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Save',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType? type,
    int? maxLen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: ctrl,
          keyboardType: type,
          maxLength: maxLen,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFFCBD5E1),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFB),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(
                color: AppTheme.primaryContainer,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
