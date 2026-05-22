// lib/features/auth/presentation/state/auth_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/branch.dart';
import '../../domain/entities/staff_member.dart';

part 'auth_state.freezed.dart';

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    Organization? selectedOrg,
    Branch? selectedBranch,
    StaffMember? loggedInStaff,
    @Default(false) bool isShiftStarted,
    @Default(false) bool isLocked,
    DateTime? shiftStartTime,
    String? errorMessage,
  }) = _AuthState;
}
