// lib/core/network/dio_retry_interceptor.dart
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:talker_flutter/talker_flutter.dart';

class DioRetryInterceptor extends Interceptor {
  final Dio dio;
  final Talker talker;
  final int maxRetries;
  final Duration baseDelay;

  DioRetryInterceptor({
    required this.dio,
    required this.talker,
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 1000),
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    
    // Check if the request is marked to skip retry
    final disableRetry = requestOptions.extra['disable_retry'] as bool? ?? false;
    if (disableRetry) {
      return handler.next(err);
    }

    final retryCount = requestOptions.headers['X-Retry-Count'] as int? ?? 0;

    if (_shouldRetry(err) && retryCount < maxRetries) {
      final nextRetryCount = retryCount + 1;
      requestOptions.headers['X-Retry-Count'] = nextRetryCount;

      final delay = baseDelay * pow(2, retryCount);
      talker.warning(
        'Retrying request [${requestOptions.method}] ${requestOptions.path} '
        '($nextRetryCount/$maxRetries) in ${delay.inMilliseconds}ms due to error: ${err.message ?? err.type.name}',
      );

      await Future.delayed(delay);

      try {
        final response = await dio.fetch(requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryErr) {
        // Recurse into error handler for subsequent retries
        return onError(retryErr, handler);
      }
    }

    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    // Retry on connection timeout, send/receive timeouts, or bad gateways / server outages
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    if (err.response != null) {
      final statusCode = err.response!.statusCode;
      if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
        return true;
      }
    }

    return false;
  }
}
