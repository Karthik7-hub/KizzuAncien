import 'user.dart';

class NotificationModel {
  final String id;
  final String message;
  final String type;
  final bool read;
  final DateTime createdAt;
  final User? sender;

  NotificationModel({
    required this.id,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
    this.sender,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
    );
  }
}
