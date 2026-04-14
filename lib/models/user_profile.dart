class UserProfile {
  UserProfile({
    required this.id,
    required this.nickname,
    required this.role,
    required this.points,
  });

  final String id;
  final String nickname;
  final String role;
  final int points;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      nickname: json['nickname'] as String? ?? '小主',
      role: json['role'] as String? ?? '我',
      points: json['points'] as int? ?? 0,
    );
  }
}
