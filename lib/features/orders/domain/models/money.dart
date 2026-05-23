// ── Money Value Object ───────────────────────────────────────────────────────
// Immutable value object for monetary amounts.
// Prevents currency mismatch errors and provides type safety.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'money.freezed.dart';
part 'money.g.dart';

@freezed
abstract class Money with _$Money implements Comparable<Money> {
  const Money._();

  const factory Money({
    required double amount,
    @Default('INR') String currency,
  }) = _Money;

  factory Money.fromJson(Map<String, dynamic> json) => _$MoneyFromJson(json);

  factory Money.zero() => const Money(amount: 0.0);

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(amount: amount + other.amount, currency: currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(amount: amount - other.amount, currency: currency);
  }

  Money operator *(double multiplier) {
    return Money(amount: amount * multiplier, currency: currency);
  }

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return amount.compareTo(other.amount);
  }

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot operate on different currencies');
    }
  }

  String format() {
    return '₹${amount.toStringAsFixed(2)}';
  }

  bool get isZero => amount == 0.0;
  bool get isPositive => amount > 0.0;
  bool get isNegative => amount < 0.0;
}
