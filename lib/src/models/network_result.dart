/// Represents the result of a network request.
/// Use pattern matching to handle [Success] and [Failure] cases.
sealed class NetworkResult<T> {
  const NetworkResult();
}

/// Returned when a request completes successfully.
class Success<T> extends NetworkResult<T> {
  const Success(this.data);

  /// The response payload.
  final T data;
}

/// Returned when a request fails due to an error or loss of connectivity.
class Failure<T> extends NetworkResult<T> {
  const Failure(this.message, {this.statusCode});

  /// The descriptive error message.
  final String message;

  /// The HTTP status code if available (e.g., 404, 500, or 499 for offline).
  final int? statusCode;
}
