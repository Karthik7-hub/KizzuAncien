import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

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
      debugPrint('Error fetching friends: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
      debugPrint('Error searching users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendFriendRequest(String recipientId) async {
    try {
      await _apiService.dio.post('/friends/request', data: {'recipientId': recipientId});
      await fetchFriends();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> respondToRequest(String requestId, String status) async {
    try {
      await _apiService.dio.post('/friends/respond', data: {'requestId': requestId, 'status': status});
      await fetchFriends();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFriend(String friendId) async {
    try {
      await _apiService.dio.delete('/friends/$friendId');
      await fetchFriends();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    // In our backend, cancel/reject can be the same as deleting the relationship record
    // We'll reuse the delete friend endpoint or create a specific one.
    // Let's check what delete friend does. It finds by requester AND recipient.
    // For cancel request, we have the requestId (the _id of the Friend document).
    try {
      await _apiService.dio.delete('/friends/request/$requestId');
      await fetchFriends();
      return true;
    } catch (e) {
      return false;
    }
  }
}
