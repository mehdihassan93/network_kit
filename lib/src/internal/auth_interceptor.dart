import 'package:dio/dio.dart';

/// **AuthInterceptor** is responsible for injecting authentication headers into every request.
///
/// It follows a **pull-based** strategy: every time a request is about to be sent,
/// it calls the provided [getToken] function to fetch the latest token. This 
/// ensures that we always use the most current token available (e.g., from secure storage).
class AuthInterceptor extends Interceptor {
  /// A callback function that returns the current authentication token.
  /// If it returns `null` or an empty string, no header will be added.
  final Future<String?> Function() getToken;

  /// Creates an [AuthInterceptor] with a required [getToken] provider.
  AuthInterceptor({required this.getToken});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Fetch the token from the provider
    final token = await getToken();
    
    // 2. Inject it into the Authorization header if present
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    // 3. Continue the request chain
    return handler.next(options);
  }
}
