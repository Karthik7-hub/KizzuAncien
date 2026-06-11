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
    return SubmissionVersion(
      versionNumber: json['versionNumber'] ?? 1,
      notes: (json['notes'] as List? ?? []).map((n) => Note.fromJson(n)).toList(),
      status: json['status'] ?? 'pending',
      reviewerNote: json['reviewerNote'],
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt']) : null,
      createdBy: json['createdBy'] != null ? User.fromJson(json['createdBy']) : null,
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
      challengeId: json['challenge'] ?? '',
      submitterId: json['submitter'] ?? '',
      currentVersion: json['currentVersion'] ?? 1,
      versions: (json['versions'] as List? ?? []).map((v) => SubmissionVersion.fromJson(v)).toList(),
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
    return ChallengeActivity(
      id: json['_id'] ?? '',
      challengeId: json['challenge'] ?? '',
      user: User.fromJson(json['user']),
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
    return Challenge(
      id: json['_id'] ?? '',
      creator: User.fromJson(json['creator']),
      recipient: User.fromJson(json['recipient']),
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
