import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'offline_storage.dart';

/// **QueueInterceptor** is the safety net that catches requests when the internet is gone.
///
/// It intercepts connectivity errors and instead of letting the app crash or show 
/// an error screen, it saves the request metadata to [OfflineStorage].
class QueueInterceptor extends Interceptor {
  /// The vault where pending requests are saved.
  final OfflineStorage storage;
  
  /// Helper to check if the device reports "No Internet".
  final Connectivity connectivity;

  /// Creates a [QueueInterceptor].
  QueueInterceptor({
    required this.storage,
    Connectivity? connectivity,
  }) : connectivity = connectivity ?? Connectivity();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 1. Detect if the failure is actually due to lack of internet
    final connectivityResult = await connectivity.checkConnectivity();
    final isNoInternet = connectivityResult.contains(ConnectivityResult.none) || 
                         err.error is SocketException;

    // 2. Filter: We only queue JSON-serializable requests, NOT file uploads (FormData).
    // File uploads often involve temporary paths that won't exist upon app restart.
    if (isNoInternet && err.requestOptions.data is! FormData) {
      
      // 3. Serialize: Map the metadata needed to recreate the request later.
      final requestMap = {
        'path': err.requestOptions.path,
        'method': err.requestOptions.method,
        'data': err.requestOptions.data,
        'queryParameters': err.requestOptions.queryParameters,
        'headers': err.requestOptions.headers,
      };

      try {
        // 4. Convert to string and save to SharedPreferences
        final jsonString = jsonEncode(requestMap);
        await storage.saveRequest(jsonString);

        // 5. Resolve: Return a fake "Success" response with status 499.
        // This tells the UI: "The system has taken care of this request offline."
        return handler.resolve(
          Response(
            requestOptions: err.requestOptions,
            statusCode: 499,
            data: {'message': 'Request queued offline'},
          ),
        );
      } catch (_) {
        // If serialization fails (e.g., non-JSON data), we let the error pass through.
      }
    }

    // 6. If internet is present or request is not queueable, proceed with the error.
    return super.onError(err, handler);
  }
}
