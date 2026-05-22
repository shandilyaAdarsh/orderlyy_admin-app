// lib/core/network/cache/dio_cache_interceptor.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:talker_flutter/talker_flutter.dart';

class CacheEntry {
  final String path;
  final dynamic responseData;
  final String? eTag;
  final DateTime cachedAt;
  final int ttlInMinutes;

  CacheEntry({
    required this.path,
    required this.responseData,
    this.eTag,
    required this.cachedAt,
    this.ttlInMinutes = 60,
  });

  bool get isExpired =>
      DateTime.now().difference(cachedAt).inMinutes >= ttlInMinutes;

  Map<String, dynamic> toJson() => {
        'path': path,
        'responseData': responseData,
        'eTag': eTag,
        'cachedAt': cachedAt.toIso8601String(),
        'ttlInMinutes': ttlInMinutes,
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
        path: json['path'] as String,
        responseData: json['responseData'],
        eTag: json['eTag'] as String?,
        cachedAt: DateTime.parse(json['cachedAt'] as String),
        ttlInMinutes: json['ttlInMinutes'] as int,
      );
}

class DioCacheInterceptor extends Interceptor {
  final Box<String> _cacheBox;
  final Talker _talker;

  DioCacheInterceptor(this._cacheBox, this._talker);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Only cache GET requests
    if (options.method != 'GET') {
      return handler.next(options);
    }

    // Skip caching if requested explicitly in extra options
    final skipCache = options.extra['skip_cache'] as bool? ?? false;
    if (skipCache) {
      return handler.next(options);
    }

    final cacheKey = options.uri.toString();
    final cachedData = _cacheBox.get(cacheKey);

    if (cachedData != null) {
      try {
        final entry = CacheEntry.fromJson(
            Map<String, dynamic>.from(jsonDecode(cachedData)));

        // If ETag exists, append it to headers for conditional validation
        if (entry.eTag != null) {
          options.headers['If-None-Match'] = entry.eTag;
        }

        // If not expired, serve local cache immediately
        if (!entry.isExpired) {
          _talker.info('Serving fresh local cache for GET: ${options.path}');
          final response = Response(
            requestOptions: options,
            data: entry.responseData,
            statusCode: 200,
            statusMessage: 'OK (From Local Cache)',
          );
          return handler.resolve(response);
        }
      } catch (e) {
        _talker.error('Failed to parse cache for key $cacheKey: $e');
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Only cache successful GET requests
    if (response.requestOptions.method == 'GET' && response.statusCode == 200) {
      final cacheKey = response.requestOptions.uri.toString();
      final eTag = response.headers.value('ETag') ?? response.headers.value('etag');
      
      final customTtl = response.requestOptions.extra['cache_ttl_minutes'] as int? ?? 60;

      final entry = CacheEntry(
        path: response.requestOptions.path,
        responseData: response.data,
        eTag: eTag,
        cachedAt: DateTime.now(),
        ttlInMinutes: customTtl,
      );

      await _cacheBox.put(cacheKey, jsonEncode(entry.toJson()));
      _talker.info('Cached response for GET: ${response.requestOptions.path} with ETag: $eTag, TTL: ${customTtl}m');
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 304 Not Modified
    if (err.response?.statusCode == 304) {
      final cacheKey = err.requestOptions.uri.toString();
      final cachedData = _cacheBox.get(cacheKey);
      if (cachedData != null) {
        try {
          final entry = CacheEntry.fromJson(
              Map<String, dynamic>.from(jsonDecode(cachedData)));
          
          // Refresh TTL by rewriting with updated timestamp
          final updatedEntry = CacheEntry(
            path: entry.path,
            responseData: entry.responseData,
            eTag: entry.eTag,
            cachedAt: DateTime.now(),
            ttlInMinutes: entry.ttlInMinutes,
          );
          await _cacheBox.put(cacheKey, jsonEncode(updatedEntry.toJson()));

          _talker.info('Server returned 304. Refreshed ETag cache TTL for: ${err.requestOptions.path}');
          
          final response = Response(
            requestOptions: err.requestOptions,
            data: entry.responseData,
            statusCode: 200,
            statusMessage: 'OK (Verified via ETag)',
          );
          return handler.resolve(response);
        } catch (e) {
          _talker.error('Error rewriting 304 cache entry: $e');
        }
      }
    }

    // Offline cache fallback if connection is lost
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      final cacheKey = err.requestOptions.uri.toString();
      final cachedData = _cacheBox.get(cacheKey);
      if (cachedData != null) {
        try {
          final entry = CacheEntry.fromJson(
              Map<String, dynamic>.from(jsonDecode(cachedData)));
          _talker.warning('Network unreachable. Serving expired/offline cache fallback for GET: ${err.requestOptions.path}');
          
          final response = Response(
            requestOptions: err.requestOptions,
            data: entry.responseData,
            statusCode: 200,
            statusMessage: 'OK (Offline Cache Fallback)',
          );
          return handler.resolve(response);
        } catch (_) {}
      }
    }

    handler.next(err);
  }
}
