import 'package:dio/dio.dart';

/// **RetryInterceptor** provides resilience against transient network failures.
///
/// It strictly targets **timeouts** (Connection, Send, Receive) to avoid 
/// unnecessary retries on logic errors like 400 (Bad Request) or 401 (Unauthorized).
class RetryInterceptor extends Interceptor {
  /// Creates a [RetryInterceptor].
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.delays = const [1000, 2000, 4000],
  });

  /// The [Dio] instance required to re-transmit the request.
  final Dio dio;

  /// The maximum number of times a single request should be retried.
  final int maxRetries;

  /// A list of delays (in milliseconds) between consecutive retries.
  /// Typically follows a pattern like [1000, 2000, 4000] for exponential backoff.
  final List<int> delays;

  /// A unique key used to track the retry count inside the [RequestOptions.extra] map.
  static const String _retryCountKey = 'network_kit_retry_count';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 1. Check current retry progress for THIS specific request
    final extra = err.requestOptions.extra;
    final int retryCount = (extra[_retryCountKey] as int?) ?? 0;

    // 2. Identify if the error is a transient timeout
    final isTimeout = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;

    // 3. Logic: If it's a timeout and we haven't hit the limit, retry.
    if (isTimeout && retryCount < maxRetries) {
      final newRetryCount = retryCount + 1;
      err.requestOptions.extra[_retryCountKey] = newRetryCount;

      // 4. Determine delay based on current retry count
      final delayIndex = retryCount < delays.length ? retryCount : delays.length - 1;
      final delay = delays[delayIndex];

      // 5. Wait...
      await Future.delayed(Duration(milliseconds: delay));

      try {
        // 6. Re-execute the request
        final response = await dio.fetch<dynamic>(err.requestOptions);
        
        // 7. If successful, resolve the original request with this response
        return handler.resolve(response);
      } on DioException catch (e) {
        // 8. If the retry fails, loop back into this error handler
        return super.onError(e, handler);
      }
    }

    // 9. If not a timeout or out of retries, propagate the error normally
    return super.onError(err, handler);
  }
}
