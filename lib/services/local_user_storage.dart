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

  /// 活动消息（任务提交/审核）最近一次查看时间（ISO8601，UTC）
  static const _keyActivityReadAt = 'activity_read_at';

  /// 订单消息（对方下单动态）最近一次查看时间（ISO8601，UTC）
  static const _keyOrderReadAt = 'order_read_at';

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

  /// 读取活动消息最近一次查看时间（ISO8601 字符串，UTC）
  static Future<String?> getActivityReadAt() async =>
      _storage.read(key: _keyActivityReadAt);

  /// 写入活动消息最近一次查看时间
  static Future<void> setActivityReadAt(String value) async =>
      _storage.write(key: _keyActivityReadAt, value: value);

  /// 读取订单消息最近一次查看时间（ISO8601 字符串，UTC）
  static Future<String?> getOrderReadAt() async =>
      _storage.read(key: _keyOrderReadAt);

  /// 写入订单消息最近一次查看时间
  static Future<void> setOrderReadAt(String value) async =>
      _storage.write(key: _keyOrderReadAt, value: value);
}
