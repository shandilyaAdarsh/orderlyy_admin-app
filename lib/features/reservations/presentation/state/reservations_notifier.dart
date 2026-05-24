// lib/features/reservations/presentation/state/reservations_notifier.dart
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/uuid.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservations_repository.dart';
import '../../data/repositories/reservations_repository_impl.dart';

part 'reservations_notifier.g.dart';

class ReservationsState {
  final List<Reservation> reservations;
  final List<WaitlistEntry> waitlist;
  final bool isLoading;
  final String? errorMessage;

  const ReservationsState({
    required this.reservations,
    required this.waitlist,
    this.isLoading = false,
    this.errorMessage,
  });

  ReservationsState copyWith({
    List<Reservation>? reservations,
    List<WaitlistEntry>? waitlist,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ReservationsState(
      reservations: reservations ?? this.reservations,
      waitlist: waitlist ?? this.waitlist,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Global Provider for ReservationsRepository
@Riverpod(keepAlive: true)
ReservationsRepository reservationsRepository(ReservationsRepositoryRef ref) {
  return ReservationsRepositoryImpl();
}

@riverpod
class ReservationsNotifier extends _$ReservationsNotifier {
  Timer? _gracePeriodTimer;

  @override
  FutureOr<ReservationsState> build() async {
    // Periodically run grace period checks (every 10 seconds for runtime responsiveness)
    _gracePeriodTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkGracePeriods();
    });

    ref.onDispose(() {
      _gracePeriodTimer?.cancel();
    });

    return _fetchState();
  }

  Future<ReservationsState> _fetchState() async {
    final repository = ref.read(reservationsRepositoryProvider);
    final resList = await repository.getReservations();
    final waitList = await repository.getWaitlist();

    // Sort waitlist by priorityScore descending
    waitList.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    return ReservationsState(
      reservations: resList,
      waitlist: waitList,
    );
  }

  Future<void> _checkGracePeriods() async {
    final currentState = state.value;
    if (currentState == null) return;

    final repository = ref.read(reservationsRepositoryProvider);
    final now = DateTime.now();
    bool updatedAny = false;

    for (final reservation in currentState.reservations) {
      if (reservation.status == ReservationStatus.booked) {
        final elapsed = now.difference(reservation.reservationTime).inMinutes;
        // 15-minute grace period expired
        if (elapsed > 15) {
          await repository.updateReservationStatus(reservation.id, ReservationStatus.noShow);
          updatedAny = true;
        }
      }
    }

    if (updatedAny) {
      final updatedState = await _fetchState();
      state = AsyncData(updatedState);
    }
  }

  Future<void> checkInReservation(String id) async {
    final repository = ref.read(reservationsRepositoryProvider);
    await repository.updateReservationStatus(id, ReservationStatus.checkedIn);
    final updatedState = await _fetchState();
    state = AsyncData(updatedState);
  }

  Future<void> seatReservation(String id, String tableId) async {
    final repository = ref.read(reservationsRepositoryProvider);
    await repository.updateReservationStatus(id, ReservationStatus.seated, tableId: tableId);
    final updatedState = await _fetchState();
    state = AsyncData(updatedState);
  }

  Future<void> addReservation(Reservation reservation) async {
    final repository = ref.read(reservationsRepositoryProvider);
    await repository.addReservation(reservation);
    final updatedState = await _fetchState();
    state = AsyncData(updatedState);
  }

  Future<void> checkInWalkIn(String guestName, String phone, int partySize, bool isVip) async {
    final repository = ref.read(reservationsRepositoryProvider);
    final entry = WaitlistEntry(
      id: UuidGenerator.generateRuntimeId(prefix: 'waitlist'),
      guestName: guestName,
      guestPhone: phone,
      guestCount: partySize,
      addedTime: DateTime.now(),
      isVip: isVip,
    );
    await repository.addWaitlistEntry(entry);
    final updatedState = await _fetchState();
    state = AsyncData(updatedState);
  }

  Future<void> seatWalkIn(String waitlistId, String tableId) async {
    final repository = ref.read(reservationsRepositoryProvider);
    final currentState = state.value;
    if (currentState == null) return;

    final walkInIndex = currentState.waitlist.indexWhere((w) => w.id == waitlistId);
    if (walkInIndex != -1) {
      final walkIn = currentState.waitlist[walkInIndex];
      // Remove from waitlist
      await repository.removeFromWaitlist(waitlistId);
      // Add as a seated reservation
      final reservation = Reservation(
        id: UuidGenerator.generateRuntimeId(prefix: 'reservation'),
        guestName: walkIn.guestName,
        guestPhone: walkIn.guestPhone,
        guestCount: walkIn.guestCount,
        reservationTime: walkIn.addedTime,
        status: ReservationStatus.seated,
        assignedTableId: tableId,
        checkedInTime: DateTime.now(),
      );
      await repository.addReservation(reservation);
      
      final updatedState = await _fetchState();
      state = AsyncData(updatedState);
    }
  }

  Future<void> cancelReservation(String id) async {
    final repository = ref.read(reservationsRepositoryProvider);
    await repository.updateReservationStatus(id, ReservationStatus.cancelled);
    final updatedState = await _fetchState();
    state = AsyncData(updatedState);
  }

  Future<void> removeWaitlist(String id) async {
    final repository = ref.read(reservationsRepositoryProvider);
    await repository.removeFromWaitlist(id);
    final updatedState = await _fetchState();
    state = AsyncData(updatedState);
  }
}
