class User {
  final String id;
  final String name;
  final String email;
  final String username;
  final String gender;
  final String? profileImageUrl;
  final String? avatarType;
  final int points;
  final int currentStreak;
  final int longestStreak;
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
    required this.points,
    required this.currentStreak,
    required this.longestStreak,
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
      points: json['points'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      sharedStreak: json['sharedStreak'],
      longestSharedStreak: json['longestSharedStreak'],
      lastStreakUpdate: json['lastStreakUpdate'] != null ? DateTime.parse(json['lastStreakUpdate']) : null,
      lastChallengeCompletedAt: json['lastChallengeCompletedAt'] != null ? DateTime.parse(json['lastChallengeCompletedAt']) : null,
    );
  }
}
