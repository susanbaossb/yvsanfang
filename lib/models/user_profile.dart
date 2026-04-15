/// 用户资料模型
/// 
/// 功能：存储和解析用户基本信息
/// 字段说明：
/// - id: 用户唯一标识（UUID，来自 Supabase Auth）
/// - nickname: 昵称
/// - role: 身份角色（我、女朋友、男朋友）
/// - points: 用户积分余额
/// - avatarUrl: 头像图片 URL
/// - email: 绑定的邮箱地址

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
