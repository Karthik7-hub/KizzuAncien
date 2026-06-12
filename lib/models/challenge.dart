import 'user.dart';

class Note {
  final String id;
  final String type;
  final String? title;
  final String content;
  final Map<String, String>? metadata;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.type,
    this.title,
    required this.content,
    this.metadata,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'explanation',
      title: json['title']?.toString(),
      content: json['content']?.toString() ?? '',
      metadata: json['metadata'] != null ? Map<String, String>.from(json['metadata']) : null,
      version: json['version'] ?? 1,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'content': content,
      'metadata': metadata,
      'version': version,
    };
  }
}

class SubmissionVersion {
  final int versionNumber;
  final List<Note> notes;
  final String status;
  final String? reviewerNote;
  final DateTime? reviewedAt;
  final User? createdBy;
  final DateTime createdAt;

  SubmissionVersion({
    required this.versionNumber,
    required this.notes,
    required this.status,
    this.reviewerNote,
    this.reviewedAt,
    this.createdBy,
    required this.createdAt,
  });

  factory SubmissionVersion.fromJson(Map<String, dynamic> json) {
    var notesList = json['notes'] as List? ?? [];
    
    return SubmissionVersion(
      versionNumber: json['versionNumber'] ?? 1,
      notes: notesList.map((n) => Note.fromJson(n)).toList(),
      status: json['status']?.toString() ?? 'pending',
      reviewerNote: json['reviewerNote']?.toString(),
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt']) : null,
      createdBy: (json['createdBy'] is Map<String, dynamic>) ? User.fromJson(json['createdBy']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class ChallengeSubmission {
  final String id;
  final String challengeId;
  final String submitterId;
  final int currentVersion;
  final List<SubmissionVersion> versions;
  final String status;

  ChallengeSubmission({
    required this.id,
    required this.challengeId,
    required this.submitterId,
    required this.currentVersion,
    required this.versions,
    required this.status,
  });

  factory ChallengeSubmission.fromJson(Map<String, dynamic> json) {
    var versionsList = json['versions'] as List? ?? [];
    
    return ChallengeSubmission(
      id: json['_id']?.toString() ?? '',
      challengeId: json['challenge'] is String ? json['challenge'] : (json['challenge']?['_id']?.toString() ?? ''),
      submitterId: json['submitter'] is String ? json['submitter'] : (json['submitter']?['_id']?.toString() ?? ''),
      currentVersion: json['currentVersion'] ?? 1,
      versions: versionsList.map((v) => SubmissionVersion.fromJson(v)).toList(),
      status: json['status']?.toString() ?? 'pending',
    );
  }
}

class ChallengeActivity {
  final String id;
  final String challengeId;
  final User user;
  final String type;
  final int? versionNumber;
  final String? message;
  final DateTime createdAt;

  ChallengeActivity({
    required this.id,
    required this.challengeId,
    required this.user,
    required this.type,
    this.versionNumber,
    this.message,
    required this.createdAt,
  });

  factory ChallengeActivity.fromJson(Map<String, dynamic> json) {
    return ChallengeActivity(
      id: json['_id']?.toString() ?? '',
      challengeId: json['challenge']?.toString() ?? '',
      user: (json['user'] is Map<String, dynamic>) 
          ? User.fromJson(json['user']) 
          : User(id: '', name: 'System', email: '', username: 'system', gender: 'other', currentStreak: 0, longestStreak: 0),
      type: json['type']?.toString() ?? '',
      versionNumber: json['versionNumber'],
      message: json['message']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class Challenge {
  final String id;
  final User creator;
  final User recipient;
  final String title;
  final String? description;
  final DateTime deadline;
  final String proofType;
  final String status;
  final String? coverImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChallengeSubmission? submission;
  
  // Discussion Metadata
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageBy;
  final Map<String, int> unreadCounts;

  Challenge({
    required this.id,
    required this.creator,
    required this.recipient,
    required this.title,
    this.description,
    required this.deadline,
    required this.proofType,
    required this.status,
    this.coverImage,
    required this.createdAt,
    required this.updatedAt,
    this.submission,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageBy,
    this.unreadCounts = const {},
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    Map<String, int> unreads = {};
    if (json['unreadCount'] != null && json['unreadCount'] is Map) {
      json['unreadCount'].forEach((key, value) {
        unreads[key.toString()] = (value as num).toInt();
      });
    }

    return Challenge(
      id: json['_id']?.toString() ?? '',
      creator: (json['creator'] is Map<String, dynamic>) 
          ? User.fromJson(json['creator']) 
          : User(id: '', name: 'Unknown', email: '', username: 'unknown', gender: 'other', currentStreak: 0, longestStreak: 0),
      recipient: (json['recipient'] is Map<String, dynamic>) 
          ? User.fromJson(json['recipient']) 
          : User(id: '', name: 'Unknown', email: '', username: 'unknown', gender: 'other', currentStreak: 0, longestStreak: 0),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      deadline: DateTime.parse(json['deadline']),
      proofType: json['proofType']?.toString() ?? 'any',
      status: json['status']?.toString() ?? 'pending',
      coverImage: json['coverImage']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      submission: json['submission'] != null ? ChallengeSubmission.fromJson(json['submission']) : null,
      lastMessage: json['lastMessage']?.toString(),
      lastMessageAt: json['lastMessageAt'] != null ? DateTime.parse(json['lastMessageAt']) : null,
      lastMessageBy: json['lastMessageBy']?.toString(),
      unreadCounts: unreads,
    );
  }
}
