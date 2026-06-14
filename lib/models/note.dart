import 'user.dart';

enum NoteType { code, explanation, image, link }

class Note {
  final String id;
  final String challengeId;
  final String title;
  final String? description;
  final NoteType type;
  final Map<String, dynamic> content;
  final User createdBy;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.challengeId,
    required this.title,
    this.description,
    required this.type,
    required this.content,
    required this.createdBy,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['_id'] ?? json['id'] ?? '',
      challengeId: json['challenge'] ?? json['challengeId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      type: _parseNoteType(json['type']),
      content: json['content'] ?? {},
      createdBy: User.fromJson(json['createdBy'] ?? {}),
      order: json['order'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'title': title,
      'description': description,
      'type': type.name,
      'content': content,
      'createdBy': createdBy.id, // Usually backend handles this, but for completeness
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static NoteType _parseNoteType(String? type) {
    switch (type?.toLowerCase()) {
      case 'code':
        return NoteType.code;
      case 'explanation':
        return NoteType.explanation;
      case 'image':
        return NoteType.image;
      case 'link':
        return NoteType.link;
      default:
        return NoteType.explanation;
    }
  }

  // Helper methods for specific content types
  String get code => content['code'] ?? '';
  String get language => content['language'] ?? 'C++';
  String get explanation => content['explanation'] ?? '';
  List<String> get images => List<String>.from(content['images'] ?? []);
  String get url => content['url'] ?? '';
}
