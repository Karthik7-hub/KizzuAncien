import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'package:kizzu_ancien/utils/logger.dart';

class FriendProvider extends ChangeNotifier {
  List<User> _friends = [];
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _outgoingRequests = [];
  List<User> _searchResults = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<User> get friends => _friends;
  List<Map<String, dynamic>> get incomingRequests => _incomingRequests;
  List<Map<String, dynamic>> get outgoingRequests => _outgoingRequests;
  List<User> get searchResults => _searchResults;
  bool get isLoading => _isLoading;

  Future<void> fetchFriends() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.dio.get('/friends');
      final data = response.data;
      
      _friends = (data['friends'] as List).map((u) => User.fromJson(u)).toList();
      _incomingRequests = (data['incoming'] as List).map((i) => {
        'id': i['id'],
        'user': User.fromJson(i['user'])
      }).toList();
      _outgoingRequests = (data['outgoing'] as List).map((o) => {
        'id': o['id'],
        'user': User.fromJson(o['user'])
      }).toList();
    } catch (e) {
      AppLogger.error('Error fetching friends', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    try {
      final response = await _apiService.dio.get('/users/profile/$userId');
      return response.data;
    } catch (e) {
      AppLogger.error('Error fetching user profile', e);
      return {};
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.dio.get('/users/search', queryParameters: {'search': query});
      _searchResults = (response.data as List).map((u) => User.fromJson(u)).toList();
    } catch (e) {
      AppLogger.error('Error searching users', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendFriendRequest(String recipientId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.dio.post('/friends/request', data: {'recipientId': recipientId});
      await fetchFriends();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> respondToRequest(String requestId, String status) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.dio.post('/friends/respond', data: {'requestId': requestId, 'status': status});
      await fetchFriends();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeFriend(String friendId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.dio.delete('/friends/$friendId');
      await fetchFriends();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.dio.delete('/friends/request/$requestId');
      await fetchFriends();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
