/// **NetworkResult** is a sealed class that represents the outcome of a network request.
///
/// By using a sealed class, we force the developer to handle both [Success] and [Failure] 
/// cases using pattern matching (switch statements), making the code more robust 
/// and less prone to unhandled exceptions.
sealed class NetworkResult<T> {
  /// Base constructor for all network results.
  const NetworkResult();
}

/// **Success** represents a successful network request.
///
/// It contains the data [T] returned by the server.
class Success<T> extends NetworkResult<T> {
  /// Creates a [Success] instance with the given [data].
  const Success(this.data);

  /// The payload returned from the API.
  final T data;
}

/// **Failure** represents a failed network request.
///
/// It provides an error [message] and an optional [statusCode] to help
/// the UI decide how to display the error.
class Failure<T> extends NetworkResult<T> {
  /// Creates a [Failure] instance with a [message] and optional [statusCode].
  const Failure(this.message, {this.statusCode});

  /// A human-readable message explaining what went wrong.
  final String message;

  /// The HTTP status code returned by the server (e.g., 404, 500, or 499 for offline).
  final int? statusCode;
}
