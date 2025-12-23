import 'package:dio/dio.dart';
import '../models/network_result.dart';

/// Utility class to map network exceptions to user-friendly messages.
class ExceptionHandler {
  /// Converts a network error into a [Failure] object.
  /// Handles common scenarios like timeouts, bad responses, and connection issues.
  static Failure<T> handleException<T>(Object error) {
    if (error is DioException) {
      switch (error.type) {
        // Connectivity and timeout issues
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const Failure('Connection timed out');

        // Server responded with an error status code
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final dynamic data = error.response?.data;
          String message = 'Server Error ($statusCode)';

          // Attempt to pull a specific error message from the response body
          if (data is Map && data.containsKey('message')) {
            message = data['message'] as String;
          } else if (data is String && data.isNotEmpty) {
            message = data;
          }
          
          return Failure(message, statusCode: statusCode);

        // Request was manually aborted
        case DioExceptionType.cancel:
          return const Failure('Request was cancelled');

        // Total lack of internet or DNS failure
        case DioExceptionType.connectionError:
          return const Failure('No internet connection');

        default:
          return Failure(error.message ?? 'Unknown network error');
      }
    }

    // fallback for generic runtime exceptions
    return const Failure('Unexpected Error');
  }
}
