/// Typed error thrown by [ApiClient] for non-2xx responses, transport errors,
/// and timeouts. Callers (repositories) can catch this to decide whether to
/// surface a message or fall back to mock data.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message, [this.details]);

  /// HTTP status code, or 0 for transport/timeout failures.
  final int statusCode;

  /// Human-readable message (taken from the backend `{ message }` envelope
  /// when available).
  final String message;

  /// Raw decoded error body, if any.
  final Object? details;

  bool get isNetworkError => statusCode == 0;
  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
