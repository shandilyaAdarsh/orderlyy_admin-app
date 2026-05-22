import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import '../config/app_config.dart';
import '../../shared/models/failures.dart'; // Contains ServerException, NetworkException, etc.
import 'dio_retry_interceptor.dart';

class DioClient {
  final Dio _dio;
  final Talker _talker;
  final void Function()? onUnauthorized;

  DioClient({
    required Talker talker,
    this.onUnauthorized,
  })  : _talker = talker,
        _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.instance.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    // Add auth interceptor to inject Bearer token from Supabase session
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final session = Supabase.instance.client.auth.currentSession;
            if (session != null) {
              final token = session.accessToken;
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {
            // Supabase not initialized or running in Mock mode
            options.headers['Authorization'] = 'Bearer mock-jwt-token';
          }
          return handler.next(options);
        },
        onError: (err, handler) {
          if (err.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          return handler.next(err);
        },
      ),
    );

    // Add exponential retry interceptor
    _dio.interceptors.add(DioRetryInterceptor(dio: _dio, talker: _talker));

    // Add Talker structured logging interceptor if enabled
    if (AppConfig.instance.enableLogging) {
      _dio.interceptors.add(
        TalkerDioLogger(
          talker: _talker,
          settings: const TalkerDioLoggerSettings(
            printRequestHeaders: true,
            printResponseHeaders: false,
            printResponseMessage: true,
          ),
        ),
      );
    }
  }

  Dio get dio => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    final response = error.response;
    final message = response?.data?['message'] ?? error.message ?? 'Unknown network error';
    final statusCode = response?.statusCode;

    if (statusCode == 401) {
      return AuthException(message);
    } else if (statusCode == 409) {
      return ConflictException(message);
    } else if (error.type == DioExceptionType.connectionTimeout ||
               error.type == DioExceptionType.receiveTimeout ||
               error.type == DioExceptionType.sendTimeout ||
               error.type == DioExceptionType.connectionError) {
      return NetworkException('Network connection error: $message');
    }

    return ServerException(
      message,
      statusCode,
    );
  }
}
