// lib/features/auth/presentation/state/auth_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/branch.dart';
import '../../domain/entities/staff_member.dart';
import 'auth_state.dart';

part 'auth_notifier.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    return const AuthState();
  }

  // Preloaded mock data for offline resiliency and simulation
  final List<Organization> mockOrganizations = const [
    Organization(id: 'org-1', name: "McDonald's Central Region"),
    Organization(id: 'org-2', name: "McDonald's APMEA Region"),
    Organization(id: 'org-3', name: 'McCafe Sandbox'),
  ];

  final Map<String, List<Branch>> mockBranches = const {
    'org-1': [
      Branch(id: 'br-1', name: 'Central Terminal Branch', status: BranchStatus.open, syncPercentage: '100%', activeStaff: 24),
      Branch(id: 'br-2', name: 'Westside Mall Express', status: BranchStatus.busy, syncPercentage: '96%', activeStaff: 12),
      Branch(id: 'br-3', name: 'Downtown Bistro', status: BranchStatus.outage, syncPercentage: '0%', activeStaff: 0),
    ],
    'org-2': [
      Branch(id: 'br-4', name: 'Singapore Changi Terminal 3', status: BranchStatus.open, syncPercentage: '100%', activeStaff: 32),
      Branch(id: 'br-5', name: 'Tokyo Shibuya Crossing', status: BranchStatus.busy, syncPercentage: '92%', activeStaff: 18),
    ],
    'org-3': [
      Branch(id: 'br-6', name: 'Sandbox Local Node', status: BranchStatus.open, syncPercentage: '100%', activeStaff: 2),
    ],
  };

  final List<StaffMember> mockStaff = const [
    StaffMember(id: 'st-1', name: 'John Doe', pin: '1234', role: StaffRole.waiter),
    StaffMember(id: 'st-2', name: 'Sarah Jenkins', pin: '5678', role: StaffRole.kdsOperator),
    StaffMember(id: 'st-3', name: 'Bob Smith', pin: '0000', role: StaffRole.manager),
  ];

  void selectOrganization(Organization org) {
    state = state.copyWith(
      selectedOrg: org,
      selectedBranch: null,
      loggedInStaff: null,
      isShiftStarted: false,
      errorMessage: null,
    );
  }

  void selectBranch(Branch branch) {
    state = state.copyWith(
      selectedBranch: branch,
      loggedInStaff: null,
      isShiftStarted: false,
      errorMessage: null,
    );
  }

  bool loginWithPIN(String pin) {
    state = state.copyWith(errorMessage: null);
    
    // Check pin credentials against mock database
    final staffIndex = mockStaff.indexWhere((s) => s.pin == pin);
    if (staffIndex != -1) {
      state = state.copyWith(
        loggedInStaff: mockStaff[staffIndex],
        isLocked: false,
      );
      return true;
    } else {
      state = state.copyWith(
        errorMessage: 'Invalid PIN code. Please try again.',
      );
      return false;
    }
  }

  void startShift(StaffRole role, String section) {
    if (state.loggedInStaff == null) return;
    
    final updatedStaff = state.loggedInStaff!.copyWith(
      role: role,
      section: section,
    );

    state = state.copyWith(
      loggedInStaff: updatedStaff,
      isShiftStarted: true,
      shiftStartTime: DateTime.now(),
      isLocked: false,
    );
  }

  void lockSession() {
    state = state.copyWith(isLocked: true);
  }

  bool unlockSession(String pin) {
    if (state.loggedInStaff?.pin == pin) {
      state = state.copyWith(isLocked: false);
      return true;
    }
    state = state.copyWith(errorMessage: 'Incorrect PIN code.');
    return false;
  }

  void endShift() {
    state = state.copyWith(
      isShiftStarted: false,
      shiftStartTime: null,
      loggedInStaff: null,
    );
  }

  void logout() {
    state = const AuthState();
  }
}
