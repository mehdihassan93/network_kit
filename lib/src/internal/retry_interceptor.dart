import 'package:dio/dio.dart';

/// Interceptor that automatically retries failed requests due to transient timeouts.
class RetryInterceptor extends Interceptor {
  /// Initializes the interceptor with retry limits and exponential backoff delays.
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.delays = const [1000, 2000, 4000],
  });

  /// The Dio instance used to re-execute the request.
  final Dio dio;
  /// Maximum number of retry attempts.
  final int maxRetries;
  /// Delays between retry attempts.
  final List<int> delays;

  static const String _retryCountKey = 'network_kit_retry_count';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final extra = err.requestOptions.extra;
    final int retryCount = (extra[_retryCountKey] as int?) ?? 0;

    // Only retry on timeouts. We skip 4xx/5xx errors to avoid infinite loops on logic errors.
    final isTimeout = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;

    if (isTimeout && retryCount < maxRetries) {
      final newRetryCount = retryCount + 1;
      err.requestOptions.extra[_retryCountKey] = newRetryCount;

      // Pick the delay based on the current attempt count.
      final delayIndex = retryCount < delays.length ? retryCount : delays.length - 1;
      final delay = delays[delayIndex];

      await Future<void>.delayed(Duration(milliseconds: delay));

      try {
        // Attempt to re-fetch the request.
        final response = await dio.fetch<dynamic>(err.requestOptions);
        return handler.resolve(response);
      } on DioException catch (e) {
        // If retry fails, recursively let the error handler decide next steps.
        return super.onError(e, handler);
      }
    }

    return super.onError(err, handler);
  }
}
