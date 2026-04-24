import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_constants.dart';
import '../utils/api_exception.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Injected after ProviderScope is set up — used to trigger session expiry.
  WidgetRef? ref;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Do NOT delete the token here. Throwing UnauthorizedException lets
          // the viewmodel decide whether this is a real session expiry
          // (e.g. during _checkAuth) or a transient failure during a background
          // call. Deleting here caused tokens to be wiped on any 401, including
          // ones that fire mid-login before the token is fully propagated.
          handler.reject(DioException(
            requestOptions: error.requestOptions,
            error: UnauthorizedException(),
            type: DioExceptionType.badResponse,
            response: error.response,
          ));
          return;
        }
        handler.next(error);
      },
    ));
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // data parameter added so DELETE /auth/fcm-token can send the token body,
  // allowing the backend to remove only this device's token on logout.
  Future<Map<String, dynamic>> delete(String path,
      {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.delete(path, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Map<String, dynamic> _handleResponse(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['success'] == false) {
        throw ApiException(
          data['error']?.toString() ?? 'An error occurred',
          statusCode: response.statusCode,
        );
      }
      return data;
    }
    return {'success': true, 'data': data};
  }

  ApiException _mapError(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkException();
    }
    // For 401s, try to use the server's error message first.
    // Only fall back to UnauthorizedException (session expired) when there
    // is no server-provided message — i.e. a true expired-token rejection.
    if (e.response?.statusCode == 401) {
      final serverMsg = (e.response?.data as Map<String, dynamic>?)?['error']
          ?.toString();
      if (serverMsg != null && serverMsg.isNotEmpty) {
        return ApiException(serverMsg, statusCode: 401);
      }
      return UnauthorizedException();
    }
    final msg = (e.response?.data as Map<String, dynamic>?)?['error']
            ?.toString() ??
        e.message ??
        'Something went wrong';
    return ApiException(msg, statusCode: e.response?.statusCode);
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.tokenKey);
  }
}
