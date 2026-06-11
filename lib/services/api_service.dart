import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;
  final storage = const FlutterSecureStorage();
  
  bool _isRefreshing = false;
  final List<void Function(String?)> _refreshQueue = [];

  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'accessToken');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 && !e.requestOptions.path.contains('/auth/')) {
          if (_isRefreshing) {
            // Queue the request until refresh is complete
            _refreshQueue.add((String? newToken) async {
              if (newToken != null) {
                e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                final opts = Options(
                  method: e.requestOptions.method,
                  headers: e.requestOptions.headers,
                );
                try {
                  final cloneReq = await dio.request(
                    e.requestOptions.path,
                    options: opts,
                    data: e.requestOptions.data,
                    queryParameters: e.requestOptions.queryParameters,
                  );
                  handler.resolve(cloneReq);
                } catch (err) {
                  handler.reject(err is DioException ? err : e);
                }
              } else {
                handler.reject(e);
              }
            });
            return;
          }

          _isRefreshing = true;
          final refreshToken = await storage.read(key: 'refreshToken');
          
          if (refreshToken != null) {
            AppLogger.info('Attempting token refresh...');
            try {
              // Use a separate Dio instance for token refresh to avoid interceptor loop
              final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
              final refreshResponse = await refreshDio.post(
                '/auth/refresh-token',
                data: {'token': refreshToken}
              );
              
              final String newAccessToken = refreshResponse.data['accessToken'];
              final String newRefreshToken = refreshResponse.data['refreshToken'];
              
              await storage.write(key: 'accessToken', value: newAccessToken);
              await storage.write(key: 'refreshToken', value: newRefreshToken);
              
              AppLogger.info('Token refresh successful');
              _isRefreshing = false;
              
              // Process queue
              final List<void Function(String?)> queue = List.from(_refreshQueue);
              _refreshQueue.clear();
              for (var callback in queue) {
                callback(newAccessToken);
              }

              // Retry original request
              e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final opts = Options(
                method: e.requestOptions.method,
                headers: e.requestOptions.headers,
              );
              final cloneReq = await dio.request(
                e.requestOptions.path,
                options: opts,
                data: e.requestOptions.data,
                queryParameters: e.requestOptions.queryParameters,
              );
              return handler.resolve(cloneReq);
            } catch (err) {
              AppLogger.error('Token refresh failed', err);
              _isRefreshing = false;
              
              // Clear tokens if the refresh token is rejected or user not found
              if (err is DioException && 
                  (err.response?.statusCode == 401 || err.response?.statusCode == 403)) {
                await storage.delete(key: 'accessToken');
                await storage.delete(key: 'refreshToken');
                
                final List<void Function(String?)> queue = List.from(_refreshQueue);
                _refreshQueue.clear();
                for (var callback in queue) {
                  callback(null);
                }
              } else {
                // For network errors, don't logout, but fail the queued requests
                final List<void Function(String?)> queue = List.from(_refreshQueue);
                _refreshQueue.clear();
                for (var callback in queue) {
                  callback(null);
                }
              }

              return handler.next(e);
            }
          } else {
            // No refresh token available
            _isRefreshing = false;
            return handler.next(e);
          }
        }
        return handler.next(e);
      },
    ));
  }
}
