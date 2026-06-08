import 'user.dart';

class Challenge {
  final String id;
  final User creator;
  final User recipient;
  final String title;
  final String? description;
  final DateTime deadline;
  final String proofType;
  final String status;
  final Map<String, dynamic>? submission;

  Challenge({
    required this.id,
    required this.creator,
    required this.recipient,
    required this.title,
    this.description,
    required this.deadline,
    required this.proofType,
    required this.status,
    this.submission,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['_id'] ?? '',
      creator: User.fromJson(json['creator']),
      recipient: User.fromJson(json['recipient']),
      title: json['title'] ?? '',
      description: json['description'],
      deadline: DateTime.parse(json['deadline']),
      proofType: json['proofType'] ?? 'any',
      status: json['status'] ?? 'pending',
      submission: json['submission'],
    );
  }
}
