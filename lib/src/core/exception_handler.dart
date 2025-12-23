import 'package:dio/dio.dart';
import '../models/network_result.dart';

/// **ExceptionHandler** is a pure utility class responsible for translating 
/// low-level networking errors into user-friendly [Failure] objects.
///
/// By centralizing error mapping here, we ensure consistent error messages
/// across the entire application and simplify future integrations with 
/// logging services like Sentry or Firebase Crashlytics.
class ExceptionHandler {
  /// Maps various error types to a structured [Failure] result.
  ///
  /// This method specifically handles:
  /// 1. **Timeouts**: (Connection, Send, Receive) mapping to "Connection timed out".
  /// 2. **Bad Responses**: Extracts error messages from the server body if available.
  /// 3. **Connectivity**: Detects pure socket/network failures.
  /// 4. **Cancellations**: Handles manual request cancellations.
  static Failure<T> handleException<T>(Object error) {
    if (error is DioException) {
      switch (error.type) {
        // Handle issues where the server took too long to respond
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const Failure('Connection timed out');

        // Handle non-200/300 HTTP status codes
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final dynamic data = error.response?.data;
          String message = 'Server Error ($statusCode)';

          // Attempt to extract a friendly message from the API response body
          if (data is Map && data.containsKey('message')) {
            message = data['message'] as String;
          } else if (data is String && data.isNotEmpty) {
            message = data;
          }
          
          return Failure(message, statusCode: statusCode);

        // Handle manual request cancellation via CancelToken
        case DioExceptionType.cancel:
          return const Failure('Request was cancelled');

        // Handle cases where the device cannot reach the network at all
        case DioExceptionType.connectionError:
          return const Failure('No internet connection');

        // Catch-all for other Dio-specific errors
        default:
          return Failure(error.message ?? 'Unknown network error');
      }
    }

    // Handle unexpected runtime exceptions not related to Dio
    return const Failure('Unexpected Error');
  }
}
