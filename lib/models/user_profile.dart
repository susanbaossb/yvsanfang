class UserProfile {
  UserProfile({
    required this.id,
    required this.nickname,
    required this.role,
    required this.points,
    this.avatarUrl,
    this.email,
  });

  final String id;
  final String nickname;
  final String role;
  final int points;
  final String? avatarUrl;
  final String? email;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      nickname: json['nickname'] as String? ?? '小主',
      role: json['role'] as String? ?? '我',
      points: json['points'] as int? ?? 0,
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
    );
  }
}
