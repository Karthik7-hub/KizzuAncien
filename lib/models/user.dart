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
  final int? sharedStreak;
  final int? longestSharedStreak;
  final DateTime? lastStreakUpdate;
  final DateTime? lastChallengeCompletedAt;
  final UserPreferences preferences;

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
    this.sharedStreak,
    this.longestSharedStreak,
    this.lastStreakUpdate,
    this.lastChallengeCompletedAt,
    required this.preferences,
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
      sharedStreak: json['sharedStreak'],
      longestSharedStreak: json['longestSharedStreak'],
      lastStreakUpdate: json['lastStreakUpdate'] != null ? DateTime.parse(json['lastStreakUpdate']) : null,
      lastChallengeCompletedAt: json['lastChallengeCompletedAt'] != null ? DateTime.parse(json['lastChallengeCompletedAt']) : null,
      preferences: json['preferences'] != null 
          ? UserPreferences.fromJson(json['preferences']) 
          : UserPreferences(
              notifications: NotificationPreferences(challenges: true, friendRequests: true, approvals: true, streaks: true),
              privacy: PrivacyPreferences(allowFriendRequests: true, allowChallengeRequests: true, profileVisibility: 'friends'),
              appearance: AppearancePreferences(theme: 'dark'),
            ),
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
    int? sharedStreak,
    int? longestSharedStreak,
    DateTime? lastStreakUpdate,
    DateTime? lastChallengeCompletedAt,
    UserPreferences? preferences,
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
      sharedStreak: sharedStreak ?? this.sharedStreak,
      longestSharedStreak: longestSharedStreak ?? this.longestSharedStreak,
      lastStreakUpdate: lastStreakUpdate ?? this.lastStreakUpdate,
      lastChallengeCompletedAt: lastChallengeCompletedAt ?? this.lastChallengeCompletedAt,
      preferences: preferences ?? this.preferences,
    );
  }
}

class UserPreferences {
  final NotificationPreferences notifications;
  final PrivacyPreferences privacy;
  final AppearancePreferences appearance;

  UserPreferences({
    required this.notifications,
    required this.privacy,
    required this.appearance,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      notifications: NotificationPreferences.fromJson(json['notifications'] ?? {}),
      privacy: PrivacyPreferences.fromJson(json['privacy'] ?? {}),
      appearance: AppearancePreferences.fromJson(json['appearance'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications.toJson(),
      'privacy': privacy.toJson(),
      'appearance': appearance.toJson(),
    };
  }
}

class NotificationPreferences {
  final bool challenges;
  final bool friendRequests;
  final bool approvals;
  final bool streaks;

  NotificationPreferences({
    required this.challenges,
    required this.friendRequests,
    required this.approvals,
    required this.streaks,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      challenges: json['challenges'] ?? true,
      friendRequests: json['friendRequests'] ?? true,
      approvals: json['approvals'] ?? true,
      streaks: json['streaks'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challenges': challenges,
      'friendRequests': friendRequests,
      'approvals': approvals,
      'streaks': streaks,
    };
  }
}

class PrivacyPreferences {
  final bool allowFriendRequests;
  final bool allowChallengeRequests;
  final String profileVisibility;

  PrivacyPreferences({
    required this.allowFriendRequests,
    required this.allowChallengeRequests,
    required this.profileVisibility,
  });

  factory PrivacyPreferences.fromJson(Map<String, dynamic> json) {
    return PrivacyPreferences(
      allowFriendRequests: json['allowFriendRequests'] ?? true,
      allowChallengeRequests: json['allowChallengeRequests'] ?? true,
      profileVisibility: json['profileVisibility'] ?? 'friends',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowFriendRequests': allowFriendRequests,
      'allowChallengeRequests': allowChallengeRequests,
      'profileVisibility': profileVisibility,
    };
  }
}

class AppearancePreferences {
  final String theme;

  AppearancePreferences({
    required this.theme,
  });

  factory AppearancePreferences.fromJson(Map<String, dynamic> json) {
    return AppearancePreferences(
      theme: json['theme'] ?? 'dark',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
    };
  }
}
