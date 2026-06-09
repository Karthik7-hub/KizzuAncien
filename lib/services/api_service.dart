import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;
  final storage = const FlutterSecureStorage();

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
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          final refreshToken = await storage.read(key: 'refreshToken');
          if (refreshToken != null) {
            try {
              // Use a fresh Dio instance to avoid recursive loops
              final refreshResponse = await Dio().post(
                '${AppConstants.apiBaseUrl}/auth/refresh-token',
                data: {'token': refreshToken}
              );
              
              final String newAccessToken = refreshResponse.data['accessToken'];
              final String newRefreshToken = refreshResponse.data['refreshToken'];
              
              await storage.write(key: 'accessToken', value: newAccessToken);
              await storage.write(key: 'refreshToken', value: newRefreshToken);
              
              // Update original request headers and retry
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
              await storage.deleteAll();
            }
          }
        }
        return handler.next(e);
      },
    ));
  }
}
