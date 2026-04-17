/// 本地用户会话存储服务
///
/// 使用 flutter_secure_storage 安全存储用户凭证
/// 替代 Supabase Auth 的匿名登录，实现真正的持久化登录

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalUserStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyUserId = 'user_id';
  static const _keyNickname = 'nickname';
  static const _keyRole = 'role';
  static const _keyEmail = 'email';

  /// 保存用户登录凭证
  static Future<void> saveUser({
    required String userId,
    required String nickname,
    required String role,
    String? email,
  }) async {
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyNickname, value: nickname);
    await _storage.write(key: _keyRole, value: role);
    if (email != null) {
      await _storage.write(key: _keyEmail, value: email);
    }
  }

  /// 获取保存的用户ID
  static Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  /// 获取保存的昵称
  static Future<String?> getNickname() async {
    return await _storage.read(key: _keyNickname);
  }

  /// 获取保存的角色
  static Future<String?> getRole() async {
    return await _storage.read(key: _keyRole);
  }

  /// 获取保存的邮箱
  static Future<String?> getEmail() async {
    return await _storage.read(key: _keyEmail);
  }

  /// 检查是否有已保存的用户
  static Future<bool> hasUser() async {
    final userId = await getUserId();
    return userId != null && userId.isNotEmpty;
  }

  /// 清除用户登录凭证
  static Future<void> clearUser() async {
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyNickname);
    await _storage.delete(key: _keyRole);
    await _storage.delete(key: _keyEmail);
  }
}
