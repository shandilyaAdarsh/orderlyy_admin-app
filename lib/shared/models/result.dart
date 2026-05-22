// ── Result Type ──────────────────────────────────────────────────────────────
// Represents the outcome of an operation that can succeed or fail.
// Used throughout the app for error handling without exceptions.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

@freezed
class Result<T, E> with _$Result<T, E> {
  const Result._();

  const factory Result.success(T value) = Success<T, E>;
  const factory Result.failure(E error) = Failure<T, E>;

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T? get valueOrNull => when(success: (value) => value, failure: (_) => null);

  E? get errorOrNull => when(success: (_) => null, failure: (error) => error);

  R fold<R>(R Function(T value) onSuccess, R Function(E error) onFailure) {
    return when(success: onSuccess, failure: onFailure);
  }

  Result<R, E> map<R>(R Function(T value) transform) {
    return when(
      success: (value) => Result.success(transform(value)),
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<R, E>> mapAsync<R>(
    Future<R> Function(T value) transform,
  ) async {
    return await when(
      success: (value) async => Result.success(await transform(value)),
      failure: (error) async => Result.failure(error),
    );
  }
}
