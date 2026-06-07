class User {
  final String id;
  final String name;
  final String email;
  final String username;
  final String gender;
  final String? profileImageUrl;
  final String? avatarType;
  final int points;
  final int streak;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.gender,
    this.profileImageUrl,
    this.avatarType,
    required this.points,
    required this.streak,
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
      streak: json['streak'] ?? 0,
    );
  }
}
