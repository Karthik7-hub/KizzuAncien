import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User, AuthProvider;
import 'package:google_sign_in/google_sign_in.dart';
import '../services/notification_service.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/logger.dart';

enum AuthStatus { authenticated, unauthenticated, offline }

class AuthProvider extends ChangeNotifier {
  User? _user;
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  AuthStatus _status = AuthStatus.unauthenticated;
  DateTime? _lastAuthCheck;
  Future<AuthStatus>? _pendingAuthCheck;
  
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
      if (e.response?.data is Map) {
        message = e.response?.data['message'] ?? 'Registration failed';
      } else if (e.response != null) {
        // Log the full response for debugging
        AppLogger.error('Server Registration Error: ${e.response?.statusCode}', e.response?.data);
        message = e.response?.data?.toString() ?? 'Server Error: ${e.response?.statusCode}';
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
      if (e.response?.data is Map) {
        message = e.response?.data['message'] ?? message;
      } else if (e.response != null) {
        String responseData = e.response?.data?.toString() ?? '';
        if (responseData.contains('Vercel authentication')) {
          message = 'Dev Server is protected by Vercel. Please disable "Deployment Protection" in Vercel settings.';
        } else {
          message = 'Server Error: ${e.response?.statusCode}';
        }
        AppLogger.error('Server Login Error: ${e.response?.statusCode}', responseData);
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
      String message = 'Google login failed';
      if (e.response?.data is Map) {
        message = e.response?.data['message'] ?? message;
      } else if (e.response != null) {
        AppLogger.error('Server Google Login Error: ${e.response?.statusCode}', e.response?.data);
        message = e.response?.data?.toString() ?? 'Server Error: ${e.response?.statusCode}';
      }
      throw Exception(message);
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

  Future<bool> trySilentLogin() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: AppConstants.googleServerClientId,
        scopes: ['email', 'profile'],
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final String? firebaseIdToken = await userCredential.user?.getIdToken();

      if (firebaseIdToken == null) return false;

      final Map<String, dynamic> googleData = {
        'googleId': userCredential.user!.uid,
        'email': userCredential.user!.email,
        'name': userCredential.user!.displayName,
        'idToken': firebaseIdToken,
      };

      final result = await googleLogin(googleData);
      return result['exists'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateProfile({String? name, String? profileImageUrl, String? gender}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.dio.put('/users/profile', data: {
        if (name != null) 'name': name,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        if (gender != null) 'gender': gender,
      });
      // The update endpoint returns the user object
      _user = User.fromJson(response.data);
      _isLoading = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoading = false;
      notifyListeners();
      String message = 'Profile update failed';
      if (e.response?.data is Map) {
        message = e.response?.data['message'] ?? message;
      } else if (e.response != null) {
        message = 'Server Error: ${e.response?.statusCode}';
      }
      throw Exception(message);
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
    await _storage.deleteAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<AuthStatus> checkAuth() async {
    // Deduplicate concurrent calls
    if (_pendingAuthCheck != null) {
      return _pendingAuthCheck!;
    }

    // Cache the result for 30 seconds to prevent "storm" calls
    if (_lastAuthCheck != null && 
        DateTime.now().difference(_lastAuthCheck!) < const Duration(seconds: 30) &&
        _user != null) {
      return _status;
    }

    _pendingAuthCheck = _performAuthCheck();
    try {
      return await _pendingAuthCheck!;
    } finally {
      _pendingAuthCheck = null;
    }
  }

  Future<AuthStatus> _performAuthCheck() async {
    final token = await _storage.read(key: 'accessToken');
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return AuthStatus.unauthenticated;
    }
    
    AppLogger.info('checkAuth called');
    try {
      // Use a longer timeout for startup check to support low internet
      final response = await _apiService.dio.get('/users/profile').timeout(
        const Duration(seconds: 15),
      );
      
      _user = User.fromJson(response.data['user']);
      _stats = response.data['stats'] ?? {};
      _status = AuthStatus.authenticated;
      _lastAuthCheck = DateTime.now();
      notifyListeners();
      return AuthStatus.authenticated;
    } on DioException catch (e) {
      // If interceptor couldn't refresh and returned 401/403
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        // Double check if we still have tokens (interceptor might have cleared them)
        final stillHasTokens = await _storage.read(key: 'refreshToken') != null;
        if (!stillHasTokens) {
          _user = null;
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return AuthStatus.unauthenticated;
        }
      }
      
      // If we have a token but can't reach the server, treat as offline
      _status = AuthStatus.offline;
      notifyListeners();
      return AuthStatus.offline; 
    } catch (e) {
      _status = AuthStatus.offline;
      notifyListeners();
      return AuthStatus.offline;
    }
  }
}
