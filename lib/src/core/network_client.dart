import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/network_result.dart';
import 'exception_handler.dart';
import '../internal/auth_interceptor.dart';
import '../internal/retry_interceptor.dart';
import '../internal/queue_interceptor.dart';
import '../internal/offline_storage.dart';

/// decodes JSON in a background isolate to keep the UI smooth.
dynamic _parseJson(String text) {
  return jsonDecode(text);
}

/// HTTP methods supported by the client.
enum HttpMethod {
  /// HTTP GET request.
  get,
  /// HTTP POST request.
  post,
  /// HTTP PUT request.
  put,
  /// HTTP PATCH request.
  patch,
  /// HTTP DELETE request.
  delete,
}

/// Main entry point for making network requests.
/// Wraps Dio with background parsing, auth, and offline queuing.
class NetworkClient {
  /// Initializes the client with a base URL and optional configurations.
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
    
    // Enable background JSON parsing using the compute function.
    _dio.transformer = BackgroundTransformer()..jsonDecodeCallback = (t) => compute(_parseJson, t);

    // Setup plumbing: Auth, Offline Queuing, and Retries.
    if (getToken != null) {
      _dio.interceptors.add(AuthInterceptor(getToken: getToken));
    }
    if (storage != null) {
      _dio.interceptors.add(QueueInterceptor(storage: storage));
    }
    _dio.interceptors.add(RetryInterceptor(dio: _dio));
  }

  final Dio _dio;

  /// Underlying Dio instance for advanced usage.
  Dio get dio => _dio;

  /// Executes a request and returns a type-safe [NetworkResult].
  Future<NetworkResult<T>> request<T>({
    required String path,
    required HttpMethod method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
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
        return Failure<T>('Response data was null');
      }

      return Success<T>(responseData as T);
    } catch (e) {
      return ExceptionHandler.handleException<T>(e);
    }
  }
}
