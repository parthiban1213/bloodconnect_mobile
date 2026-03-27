import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        // Fix #6: log all outgoing API calls
        debugPrint('[API] ▶ ${options.method} ${options.path}'
            '${options.queryParameters.isNotEmpty ? ' | query: ${options.queryParameters}' : ''}'
            '${options.data != null ? ' | body: ${options.data}' : ''}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Fix #6: log successful responses
        debugPrint('[API] ✓ ${response.statusCode} ${response.requestOptions.method} '
            '${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) async {
        // Fix #6: log errors
        debugPrint('[API] ✗ ${error.response?.statusCode ?? 'ERR'} '
            '${error.requestOptions.method} ${error.requestOptions.path} '
            '→ ${error.message}');
        if (error.response?.statusCode == 401) {
          await _storage.delete(key: AppConstants.tokenKey);
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

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
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
    if (e.response?.statusCode == 401) return UnauthorizedException();
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
