// lib/features/tables/data/dtos/table_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'table_dto.freezed.dart';
part 'table_dto.g.dart';

@freezed
abstract class GuestSeatDto with _$GuestSeatDto {
  const factory GuestSeatDto({
    @JsonKey(name: 'seat_number') required int seatNumber,
    @JsonKey(name: 'guest_name') String? guestName,
    @JsonKey(name: 'ordered_item_ids') @Default([]) List<String> orderedItemIds,
  }) = _GuestSeatDto;

  factory GuestSeatDto.fromJson(Map<String, dynamic> json) => _$GuestSeatDtoFromJson(json);
}

@freezed
abstract class TableDto with _$TableDto {
  const factory TableDto({
    required String id,
    required String label,
    required int capacity,
    required String status,
    @JsonKey(name: 'active_order_id') String? activeOrderId,
    @JsonKey(name: 'occupied_seats') @Default([]) List<GuestSeatDto> occupiedSeats,
    @JsonKey(name: 'merged_table_ids') @Default([]) List<String> mergedTableIds,
  }) = _TableDto;

  factory TableDto.fromJson(Map<String, dynamic> json) => _$TableDtoFromJson(json);
}
