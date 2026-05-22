// ── Failure Types ────────────────────────────────────────────────────────────
// Represents different types of failures that can occur in the app.
// All failures are serializable for logging and debugging.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';
part 'failures.g.dart';

@freezed
abstract class AppFailure with _$AppFailure {
  const factory AppFailure.server({required String message, int? statusCode}) =
      ServerFailure;

  const factory AppFailure.network({required String message}) = NetworkFailure;

  const factory AppFailure.cache({required String message}) = CacheFailure;

  const factory AppFailure.notFound({required String message}) =
      NotFoundFailure;

  const factory AppFailure.validation({
    required String message,
    Map<String, List<String>>? errors,
  }) = ValidationFailure;

  const factory AppFailure.unauthorized({required String message}) =
      UnauthorizedFailure;

  const factory AppFailure.unknown({required String message}) = UnknownFailure;

  factory AppFailure.fromJson(Map<String, dynamic> json) =>
      _$AppFailureFromJson(json);
}

// ── Exception Types ──────────────────────────────────────────────────────────

class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException(this.message, [this.statusCode]);

  @override
  String toString() => 'ServerException: $message (${statusCode ?? 'unknown'})';
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;

  CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class ConflictException implements Exception {
  final String message;

  ConflictException(this.message);

  @override
  String toString() => 'ConflictException: $message';
}

// ── Exception to Failure Mapping ─────────────────────────────────────────────

AppFailure mapExceptionToFailure(Exception exception) {
  if (exception is ServerException) {
    return AppFailure.server(
      message: exception.message,
      statusCode: exception.statusCode,
    );
  } else if (exception is NetworkException) {
    return AppFailure.network(message: exception.message);
  } else if (exception is CacheException) {
    return AppFailure.cache(message: exception.message);
  } else if (exception is AuthException) {
    return AppFailure.unauthorized(message: exception.message);
  } else if (exception is ConflictException) {
    return AppFailure.validation(message: exception.message);
  } else {
    return AppFailure.unknown(message: exception.toString());
  }
}
