import 'user.dart';

class Note {
  final String id;
  final String type; // explanation, code, image, link
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
      id: json['_id'] ?? '',
      type: json['type'] ?? 'explanation',
      title: json['title'],
      content: json['content'] ?? '',
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
    // Safety check: createdBy might be a String ID or a populated Map
    User? author;
    if (json['createdBy'] != null) {
      if (json['createdBy'] is Map<String, dynamic>) {
        author = User.fromJson(json['createdBy']);
      } else {
        // It's a String ID, we can't create a full User object but we avoid crashing
        // The UI will just show 'Unknown' or fallback to challenge recipient
      }
    }

    return SubmissionVersion(
      versionNumber: json['versionNumber'] ?? 1,
      notes: (json['notes'] as List? ?? []).map((n) => Note.fromJson(n)).toList(),
      status: json['status'] ?? 'pending',
      reviewerNote: json['reviewerNote'],
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt']) : null,
      createdBy: author,
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
    return ChallengeSubmission(
      id: json['_id'] ?? '',
      challengeId: json['challenge'] is String ? json['challenge'] : (json['challenge']?['_id'] ?? ''),
      submitterId: json['submitter'] is String ? json['submitter'] : (json['submitter']?['_id'] ?? ''),
      currentVersion: json['currentVersion'] ?? 1,
      versions: (json['versions'] as List? ?? []).map((v) {
        if (v is Map<String, dynamic>) {
          return SubmissionVersion.fromJson(v);
        }
        // Fallback for unexpected data format
        return SubmissionVersion(versionNumber: 0, notes: [], status: 'error', createdAt: DateTime.now());
      }).toList(),
      status: json['status'] ?? 'pending',
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
    User? activityUser;
    if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      activityUser = User.fromJson(json['user']);
    } else {
      // Fallback user if populate fails
      activityUser = User(id: '', name: 'System', email: '', username: 'system', gender: 'other', currentStreak: 0, longestStreak: 0);
    }

    return ChallengeActivity(
      id: json['_id'] ?? '',
      challengeId: json['challenge'] ?? '',
      user: activityUser,
      type: json['type'] ?? '',
      versionNumber: json['versionNumber'],
      message: json['message'],
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
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    User? creatorUser;
    if (json['creator'] is Map<String, dynamic>) {
      creatorUser = User.fromJson(json['creator']);
    } else {
      creatorUser = User(id: json['creator'] ?? '', name: 'Unknown', email: '', username: 'unknown', gender: 'other', currentStreak: 0, longestStreak: 0);
    }

    User? recipientUser;
    if (json['recipient'] is Map<String, dynamic>) {
      recipientUser = User.fromJson(json['recipient']);
    } else {
      recipientUser = User(id: json['recipient'] ?? '', name: 'Unknown', email: '', username: 'unknown', gender: 'other', currentStreak: 0, longestStreak: 0);
    }

    return Challenge(
      id: json['_id'] ?? '',
      creator: creatorUser,
      recipient: recipientUser,
      title: json['title'] ?? '',
      description: json['description'],
      deadline: DateTime.parse(json['deadline']),
      proofType: json['proofType'] ?? 'any',
      status: json['status'] ?? 'pending',
      coverImage: json['coverImage'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      submission: json['submission'] != null ? ChallengeSubmission.fromJson(json['submission']) : null,
    );
  }
}
