import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/notification_service.dart';
import '../models/user.dart';
import '../services/api_service.dart';

import 'package:kizzu_ancien/utils/logger.dart';

import 'package:google_sign_in/google_sign_in.dart';
import '../utils/constants.dart';
import '../utils/session_utils.dart';

enum AuthStatus { authenticated, unauthenticated, offline }

class AuthProvider extends ChangeNotifier {
  User? _user;
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  AuthStatus _status = AuthStatus.unauthenticated;
  
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  User? get user => _user;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  AuthStatus get status => _status;

  Future<bool> register(String name, String username, String email, String password, String gender) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.dio.post('/auth/register', data: {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'gender': gender,
      });
      
      if (response.data['user'] != null) {
        _user = User.fromJson(response.data['user']);
        await _storage.write(key: 'accessToken', value: response.data['accessToken']);
        await _storage.write(key: 'refreshToken', value: response.data['refreshToken']);
        await NotificationService.setupFcmToken();
        _status = AuthStatus.authenticated;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      
      String message = 'Connection refused. Is the server running?';
      if (e.response != null) {
        message = e.response?.data['message'] ?? 'Registration failed';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Server timed out. Check your database connection.';
      }
      
      throw Exception(message);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Unexpected error: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      _user = User.fromJson(response.data['user']);
      await _storage.write(key: 'accessToken', value: response.data['accessToken']);
      await _storage.write(key: 'refreshToken', value: response.data['refreshToken']);
      await NotificationService.setupFcmToken();
      
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      String message = 'Login failed';
      if (e.response != null) {
        message = e.response?.data['message'] ?? message;
      }
      throw Exception(message);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> googleLogin(Map<String, dynamic> googleData, {String? gender, String? username}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final filteredData = Map<String, dynamic>.from(googleData);
      filteredData.remove('avatarUrl');
      filteredData.remove('photoUrl');
      filteredData.remove('picture');

      if (gender != null) filteredData['gender'] = gender;
      if (username != null) filteredData['username'] = username;

      final response = await _apiService.dio.post('/auth/google', data: filteredData);
      
      if (response.data['exists'] == true) {
        _user = User.fromJson(response.data['user']);
        await _storage.write(key: 'accessToken', value: response.data['accessToken']);
        await _storage.write(key: 'refreshToken', value: response.data['refreshToken']);
        await NotificationService.setupFcmToken();
        _status = AuthStatus.authenticated;
      }
      
      _isLoading = false;
      notifyListeners();
      return response.data; // Return full response to handle 'exists: false'
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception(e.response?.data['message'] ?? 'Google login failed');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> checkEmail(String email) async {
    try {
      final response = await _apiService.dio.get('/auth/check-email/$email');
      return response.data['exists'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateProfile({String? name, String? profileImageUrl, String? gender, String? username}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.dio.put('/users/profile', data: {
        if (name != null) 'name': name,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        if (gender != null) 'gender': gender,
        if (username != null) 'username': username,
      });
      // The update endpoint returns the user object
      _user = User.fromJson(response.data);
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception(e.response?.data['message'] ?? 'Profile update failed');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> checkUsername(String username, {String? excludeUserId}) async {
    try {
      final queryParams = {
        'username': username,
        if (excludeUserId != null) 'excludeUserId': excludeUserId,
      };
      final response = await _apiService.dio.get('/users/check-username', queryParameters: queryParams);
      return response.data['exists'] ?? false;
    } catch (e) {
      AppLogger.error('Error checking username', e);
      return false;
    }
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.dio.delete('/users/profile');
      
      // Clean up local Google sign out
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: AppConstants.googleServerClientId,
        );
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
          await googleSignIn.disconnect();
        }
      } catch (e) {
        AppLogger.error('Google SignOut error during account deletion', e);
      }

      SessionUtils.clearAllData();
      await _storage.deleteAll();
      _user = null;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception(e.response?.data['message'] ?? 'Account deletion failed');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }


  Future<void> logout() async {
    try {
      await _apiService.dio.put('/users/fcm-token', data: {'fcmToken': null});
    } catch (e) {
      // Silently fail logout server-side update
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: AppConstants.googleServerClientId,
      );
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        await googleSignIn.disconnect(); // Fully disconnect to force account picker
      }
    } catch (e) {
      AppLogger.error('Google SignOut error', e);
    }

    SessionUtils.clearAllData();

    await _storage.deleteAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<AuthStatus> checkAuth() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return AuthStatus.unauthenticated;
      }
      
      // Proactively check profile. If it fails with 401, ApiService interceptor 
      // will attempt refresh automatically before returning here.
      final response = await _apiService.dio.get('/users/profile').timeout(
        const Duration(seconds: 10),
      );
      
      if (response.data['user'] == null) {
        AppLogger.error('checkAuth: user data is null in response');
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return AuthStatus.unauthenticated;
      }

      _user = User.fromJson(response.data['user']);
      _stats = response.data['stats'] ?? {};
      _status = AuthStatus.authenticated;
      notifyListeners();
      return AuthStatus.authenticated;
    } on DioException catch (e) {
      AppLogger.error('checkAuth DioException: ${e.type}', e);
      
      // If we reach here after interceptor failure, logout
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        await logout();
        return AuthStatus.unauthenticated;
      }
      
      // Network/Server issues
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.badCertificate ||
          e.type == DioExceptionType.unknown) {
        
        _status = AuthStatus.offline;
        notifyListeners();
        return AuthStatus.offline; 
      }
      
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return AuthStatus.unauthenticated;
    } catch (e, stack) {
      AppLogger.error('checkAuth unexpected error', e, stack);
      _status = AuthStatus.offline;
      notifyListeners();
      return AuthStatus.offline;
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.dio.put('/users/profile', data: {
        'preferences': preferences,
      });
      _user = User.fromJson(response.data);
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception(e.response?.data['message'] ?? 'Preferences update failed');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
