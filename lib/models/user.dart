class User {
  final String id;
  final String name;
  final String email;
  final String username;
  final String gender;
  final String? profileImageUrl;
  final String? avatarType;
  final int? relationshipPoints;
  final int currentStreak;
  final int longestStreak;
  final String? relationshipStatus;
  final String? requestId;
  final int? sharedStreak;
  final int? longestSharedStreak;
  final DateTime? lastStreakUpdate;
  final DateTime? lastChallengeCompletedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.gender,
    this.profileImageUrl,
    this.avatarType,
    this.relationshipPoints,
    required this.currentStreak,
    required this.longestStreak,
    this.relationshipStatus,
    this.requestId,
    this.sharedStreak,
    this.longestSharedStreak,
    this.lastStreakUpdate,
    this.lastChallengeCompletedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      gender: json['gender'] ?? 'male',
      profileImageUrl: json['profileImageUrl'],
      avatarType: json['avatarType'],
      relationshipPoints: json['relationshipPoints'],
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      relationshipStatus: json['relationshipStatus'],
      requestId: json['requestId'],
      sharedStreak: json['sharedStreak'],
      longestSharedStreak: json['longestSharedStreak'],
      lastStreakUpdate: json['lastStreakUpdate'] != null ? DateTime.parse(json['lastStreakUpdate']) : null,
      lastChallengeCompletedAt: json['lastChallengeCompletedAt'] != null ? DateTime.parse(json['lastChallengeCompletedAt']) : null,
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    String? gender,
    String? profileImageUrl,
    String? avatarType,
    int? relationshipPoints,
    int? currentStreak,
    int? longestStreak,
    String? relationshipStatus,
    String? requestId,
    int? sharedStreak,
    int? longestSharedStreak,
    DateTime? lastStreakUpdate,
    DateTime? lastChallengeCompletedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      avatarType: avatarType ?? this.avatarType,
      relationshipPoints: relationshipPoints ?? this.relationshipPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      requestId: requestId ?? this.requestId,
      sharedStreak: sharedStreak ?? this.sharedStreak,
      longestSharedStreak: longestSharedStreak ?? this.longestSharedStreak,
      lastStreakUpdate: lastStreakUpdate ?? this.lastStreakUpdate,
      lastChallengeCompletedAt: lastChallengeCompletedAt ?? this.lastChallengeCompletedAt,
    );
  }
}
