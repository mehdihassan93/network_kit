import 'package:dio/dio.dart';

/// Interceptor that adds an Authorization header to every request.
class AuthInterceptor extends Interceptor {
  /// Requires a [getToken] callback to pull the latest token (e.g., from secure storage).
  AuthInterceptor({required this.getToken});

  /// Function to fetch the current token.
  final Future<String?> Function() getToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Pull the latest token before sending the request.
    final token = await getToken();
    
    // Add Bearer token if available.
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    return handler.next(options);
  }
}
