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
