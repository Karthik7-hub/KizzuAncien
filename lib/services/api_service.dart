import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiService {
  static String get baseUrl => AppConstants.apiBaseUrl;

  final Dio dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));
  
  final storage = const FlutterSecureStorage();

  ApiService() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        debugPrint('🌐 API REQUEST[${options.method}] => ${options.baseUrl}${options.path}');
        final token = await storage.read(key: 'accessToken');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('✅ API RESPONSE[${response.statusCode}]');
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        debugPrint('❌ API ERROR: ${e.type} => ${e.message}');
        if (e.response != null) {
          debugPrint('❌ DATA: ${e.response?.data}');
        }
        
        if (e.response?.statusCode == 401) {
          final refreshToken = await storage.read(key: 'refreshToken');
          if (refreshToken != null) {
            try {
              final response = await Dio().post('$baseUrl/auth/refresh-token', data: {'token': refreshToken});
              final newToken = response.data['accessToken'];
              await storage.write(key: 'accessToken', value: newToken);
              
              e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final cloneReq = await dio.request(
                e.requestOptions.path,
                options: Options(
                  method: e.requestOptions.method,
                  headers: e.requestOptions.headers,
                ),
                data: e.requestOptions.data,
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
