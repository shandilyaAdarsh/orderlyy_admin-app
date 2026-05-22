// lib/features/reservations/domain/repositories/reservations_repository.dart
import '../entities/reservation.dart';

abstract class ReservationsRepository {
  Future<List<Reservation>> getReservations();
  Future<List<WaitlistEntry>> getWaitlist();
  Future<void> addReservation(Reservation reservation);
  Future<void> addWaitlistEntry(WaitlistEntry entry);
  Future<void> updateReservationStatus(String id, ReservationStatus status, {String? tableId});
  Future<void> removeFromWaitlist(String id);
}
