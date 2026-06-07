import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/notification.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.dio.get('/notifications');
      _notifications = (response.data as List).map((n) => NotificationModel.fromJson(n)).toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead() async {
    try {
      await _apiService.dio.put('/notifications/read');
      await fetchNotifications();
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }
}
