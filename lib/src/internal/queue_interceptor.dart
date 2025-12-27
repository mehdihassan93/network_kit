import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'offline_storage.dart';

/// Interceptor that captures and queues failed mutation requests while the device is offline.
class QueueInterceptor extends Interceptor {
  /// Initializes the interceptor with persistent storage and optional connectivity monitor.
  QueueInterceptor({
    required this.storage,
    Connectivity? connectivity,
  }) : connectivity = connectivity ?? Connectivity();

  /// Persistent storage for the offline queue.
  final OfflineStorage storage;
  /// Connectivity monitor for detecting network status.
  final Connectivity connectivity;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Check if the error is connectivity-related.
    final connectivityResult = await connectivity.checkConnectivity();
    final isNoInternet = connectivityResult.contains(ConnectivityResult.none) || 
                         err.error is SocketException;

    // Filter: only queue simple mutations. Files (FormData) are skipped 
    // because their temporary paths might not exist when replaying.
    final skipQueue = err.requestOptions.extra['skipQueue'] == true;
    if (!skipQueue && isNoInternet && err.requestOptions.data is! FormData) {
      
      // Serialize minimum metadata needed to recreate the request.
      final headers = Map<String, dynamic>.from(err.requestOptions.headers);
      // Remove headers that Dio or the server might auto-generate/conflict with.
      headers.remove(HttpHeaders.contentLengthHeader);
      headers.remove(HttpHeaders.hostHeader);

      final requestMap = {
        'path': err.requestOptions.path,
        'method': err.requestOptions.method,
        'data': err.requestOptions.data,
        'queryParameters': err.requestOptions.queryParameters,
        'headers': headers,
      };

      try {
        final jsonString = jsonEncode(requestMap);
        await storage.saveRequest(jsonString);

        // Resolve with status 499 to signal to the UI that the request was queued.
        return handler.resolve(
          Response<dynamic>(
            requestOptions: err.requestOptions,
            statusCode: 499,
            data: {'message': 'Request queued offline'},
          ),
        );
      } catch (_) {
        // Fallback to original error if serialization fails.
      }
    }

    return super.onError(err, handler);
  }
}
