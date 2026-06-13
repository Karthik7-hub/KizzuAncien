import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/notification.dart';
import 'package:kizzu_ancien/utils/logger.dart';

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
      AppLogger.error('Error fetching notifications', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead() async {
    try {
      await _apiService.dio.put('/notifications/read');
      _notifications = _notifications.map((n) => NotificationModel(
        id: n.id,
        message: n.message,
        type: n.type,
        read: true,
        createdAt: n.createdAt,
        sender: n.sender,
      )).toList();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error marking notifications as read', e);
    }
  }
}
