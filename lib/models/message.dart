import 'user.dart';

class Message {
  final String id;
  final String challengeId;
  final User sender;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.challengeId,
    required this.sender,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      challengeId: json['challenge'] ?? '',
      sender: User.fromJson(json['sender']),
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}
