class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException() : super('No internet connection. Please check your network.');
}

class UnauthorizedException extends ApiException {
  UnauthorizedException() : super('Session expired. Please log in again.', statusCode: 401);
}

/// Thrown when the mobile number is already registered during sign-up.
class MobileAlreadyExistsException implements Exception {
  final String message =
      'This mobile number is already registered. Please login instead.';
  @override
  String toString() => message;
}
