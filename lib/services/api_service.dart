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
          final requestOptions = e.requestOptions;
          if (_isRefreshing) {
            // Queue the request until refresh is complete
            _refreshQueue.add((String? newToken) async {
              if (newToken != null) {
                requestOptions.headers['Authorization'] = 'Bearer $newToken';
                final opts = Options(
                  method: requestOptions.method,
                  headers: requestOptions.headers,
                );
                try {
                  final cloneReq = await dio.request(
                    requestOptions.path,
                    options: opts,
                    data: requestOptions.data,
                    queryParameters: requestOptions.queryParameters,
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
              // Create a fresh Dio instance for the refresh call to avoid 
              // the global interceptor's possible infinite loops/queue issues.
              final refreshDio = Dio();
              final refreshResponse = await refreshDio.post(
                '${AppConstants.apiBaseUrl}/auth/refresh-token',
                data: {'token': refreshToken}
              );
              
              final String newAccessToken = refreshResponse.data['accessToken'];
              final String newRefreshToken = refreshResponse.data['refreshToken'];
              
              await storage.write(key: 'accessToken', value: newAccessToken);
              await storage.write(key: 'refreshToken', value: newRefreshToken);
              
              _isRefreshing = false;
              
              // Process queue
              final callbacks = List<void Function(String?)>.from(_refreshQueue);
              _refreshQueue.clear();
              for (var callback in callbacks) {
                callback(newAccessToken);
              }

              // Retry original request
              requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final opts = Options(
                method: requestOptions.method,
                headers: requestOptions.headers,
              );
              final cloneReq = await dio.request(
                requestOptions.path,
                options: opts,
                data: requestOptions.data,
                queryParameters: requestOptions.queryParameters,
              );
              return handler.resolve(cloneReq);
            } catch (err) {
              _isRefreshing = false;
              await storage.deleteAll();
              final callbacks = List<void Function(String?)>.from(_refreshQueue);
              _refreshQueue.clear();
              for (var callback in callbacks) {
                callback(null);
              }
              return handler.next(e);
            }
          }
        }
        return handler.next(e);
      },
    ));
  }
}
