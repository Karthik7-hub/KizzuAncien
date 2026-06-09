import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

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
        if (e.response?.statusCode == 401) {
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
            try {
              final refreshResponse = await Dio().post(
                '${AppConstants.apiBaseUrl}/auth/refresh-token',
                data: {'token': refreshToken}
              );
              
              final String newAccessToken = refreshResponse.data['accessToken'];
              final String newRefreshToken = refreshResponse.data['refreshToken'];
              
              await storage.write(key: 'accessToken', value: newAccessToken);
              await storage.write(key: 'refreshToken', value: newRefreshToken);
              
              _isRefreshing = false;
              
              // Process queue
              for (var callback in _refreshQueue) {
                callback(newAccessToken);
              }
              _refreshQueue.clear();

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
              _isRefreshing = false;
              await storage.deleteAll();
              for (var callback in _refreshQueue) {
                callback(null);
              }
              _refreshQueue.clear();
              return handler.next(e);
            }
          }
        }
        return handler.next(e);
      },
    ));
  }
}
