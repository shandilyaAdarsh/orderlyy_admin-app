// lib/features/reservations/data/repositories/reservations_repository_impl.dart
import 'dart:async';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservations_repository.dart';

class ReservationsRepositoryImpl implements ReservationsRepository {
  final List<Reservation> _reservations = [];
  final List<WaitlistEntry> _waitlist = [];

  ReservationsRepositoryImpl() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();
    _reservations.addAll([
      Reservation(
        id: 'res-1',
        guestName: 'Alex Mercer',
        guestPhone: '+1 555-0192',
        guestCount: 4,
        reservationTime: now.add(const Duration(minutes: 10)),
        status: ReservationStatus.booked,
      ),
      Reservation(
        id: 'res-2',
        guestName: 'Beatrix Kiddo',
        guestPhone: '+1 555-0283',
        guestCount: 2,
        reservationTime: now.add(const Duration(minutes: 45)),
        status: ReservationStatus.booked,
      ),
      Reservation(
        id: 'res-3',
        guestName: 'Charles Xavier',
        guestPhone: '+1 555-0374',
        guestCount: 6,
        reservationTime: now.subtract(const Duration(minutes: 8)),
        status: ReservationStatus.checkedIn,
        checkedInTime: now.subtract(const Duration(minutes: 8)),
      ),
      Reservation(
        id: 'res-4',
        guestName: 'Diana Prince',
        guestPhone: '+1 555-0465',
        guestCount: 3,
        reservationTime: now.subtract(const Duration(minutes: 20)),
        status: ReservationStatus.booked, // No-show soon if grace period triggers
      ),
    ]);

    _waitlist.addAll([
      WaitlistEntry(
        id: 'wait-1',
        guestName: 'Bruce Wayne',
        guestPhone: '+1 555-0099',
        guestCount: 2,
        addedTime: now.subtract(const Duration(minutes: 12)),
        isVip: true,
      ),
      WaitlistEntry(
        id: 'wait-2',
        guestName: 'Clark Kent',
        guestPhone: '+1 555-0088',
        guestCount: 4,
        addedTime: now.subtract(const Duration(minutes: 20)),
        isVip: false,
      ),
      WaitlistEntry(
        id: 'wait-3',
        guestName: 'Peter Parker',
        guestPhone: '+1 555-0077',
        guestCount: 1,
        addedTime: now.subtract(const Duration(minutes: 5)),
        isVip: false,
      ),
    ]);
  }

  @override
  Future<List<Reservation>> getReservations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_reservations);
  }

  @override
  Future<List<WaitlistEntry>> getWaitlist() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_waitlist);
  }

  @override
  Future<void> addReservation(Reservation reservation) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _reservations.add(reservation);
  }

  @override
  Future<void> addWaitlistEntry(WaitlistEntry entry) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _waitlist.add(entry);
  }

  @override
  Future<void> updateReservationStatus(String id, ReservationStatus status, {String? tableId}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _reservations.indexWhere((r) => r.id == id);
    if (index != -1) {
      final old = _reservations[index];
      _reservations[index] = old.copyWith(
        status: status,
        assignedTableId: tableId ?? old.assignedTableId,
        checkedInTime: status == ReservationStatus.checkedIn ? DateTime.now() : old.checkedInTime,
      );
    }
  }

  @override
  Future<void> removeFromWaitlist(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _waitlist.removeWhere((w) => w.id == id);
  }
}
