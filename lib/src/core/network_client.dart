import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/network_result.dart';
import 'exception_handler.dart';
import '../internal/auth_interceptor.dart';
import '../internal/retry_interceptor.dart';
import '../internal/queue_interceptor.dart';
import '../internal/offline_storage.dart';

/// Top-level function for background JSON parsing to avoid UI thread blocking.
dynamic _parseJson(String text) {
  return jsonDecode(text);
}

/// Supported HTTP methods for the [NetworkClient].
enum HttpMethod {
  /// GET request
  get,
  /// POST request
  post,
  /// PUT request
  put,
  /// PATCH request
  patch,
  /// DELETE request
  delete,
}

/// **NetworkClient** is the primary interface for making network requests.
///
/// It wraps the `Dio` HTTP client with production-grade optimizations:
/// - **Background Parsing**: JSON decoding happens in a separate isolate.
/// - **Authentication**: Interceptor-based token injection.
/// - **Offline Support**: Mutation queuing and persistence.
class NetworkClient {
  final Dio _dio;

  /// Creates a [NetworkClient] instance.
  NetworkClient({
    required String baseUrl,
    Future<String?> Function()? getToken,
    OfflineStorage? storage,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
              ),
            ) {
    
    // Optimized: Move JSON decoding to a background isolate (compute) to prevent UI Jank.
    // Note: Using DefaultTransformer which allows setting the jsonDecodeCallback.
    (_dio.transformer as DefaultTransformer).jsonDecodeCallback = (t) => compute(_parseJson, t);

    // Interceptors
    if (getToken != null) {
      _dio.interceptors.add(AuthInterceptor(getToken: getToken));
    }
    if (storage != null) {
      _dio.interceptors.add(QueueInterceptor(storage: storage));
    }
    _dio.interceptors.add(RetryInterceptor(dio: _dio));
  }

  /// Exposes the raw [Dio] instance if needed.
  Dio get dio => _dio;

  /// Performs a network request and returns a [NetworkResult].
  Future<NetworkResult<T>> request<T>({
    required String path,
    required HttpMethod method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: (options ?? Options()).copyWith(
          method: method.name.toUpperCase(),
        ),
      );

      final responseData = response.data;

      if (responseData == null) {
        return const Failure('Response data was null');
      }

      return Success(responseData as T);
    } catch (e) {
      return ExceptionHandler.handleException<T>(e);
    }
  }
}
