/// 认证服务
/// 
/// 功能：
/// 1. currentUserId: 获取当前用户 ID（来自本地存储）
/// 2. fetchMyProfile: 获取当前用户资料
/// 3. saveProfile: 保存用户资料（昵称、身份、头像、邮箱）
/// 4. createUser: 创建新用户（使用本地生成的 UUID）
/// 5. findUserByNameOrEmail: 通过昵称或邮箱查找用户
/// 6. uploadAvatar: 上传用户头像到 Storage

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/supabase_client.dart';
import '../models/user_profile.dart';
import 'local_user_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  String? _currentUserId;

  /// 获取当前用户 ID（从本地存储获取）
  String? get currentUserId => _currentUserId;

  /// 初始化当前用户（从本地存储恢复）
  Future<void> initCurrentUser() async {
    _currentUserId = await LocalUserStorage.getUserId();
    debugPrint('AuthService: currentUserId = $_currentUserId');
  }

  /// 检查是否有已登录用户
  Future<bool> hasLoggedInUser() async {
    return await LocalUserStorage.hasUser();
  }

  /// 通过昵称或邮箱查找用户
  Future<UserProfile?> findUserByNameOrEmail(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final result = await AppSupabase.client
        .from('profiles')
        .select()
        .or('nickname.ilike.$trimmed,email.ilike.$trimmed')
        .maybeSingle();

    if (result == null) return null;
    return UserProfile.fromJson(result);
  }

  /// 获取当前用户资料
  Future<UserProfile?> fetchMyProfile() async {
    final id = _currentUserId;
    if (id == null) return null;

    final result = await AppSupabase.client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (result == null) return null;
    return UserProfile.fromJson(result);
  }

  /// 创建新用户（本地生成 UUID 作为 ID）
  Future<UserProfile> createUser({
    required String nickname,
    required String role,
    String? email,
  }) async {
    final userId = const Uuid().v4();
    
    // 保存到本地
    await LocalUserStorage.saveUser(
      userId: userId,
      nickname: nickname,
      role: role,
      email: email,
    );
    _currentUserId = userId;

    // 保存到数据库
    final data = <String, dynamic>{
      'id': userId,
      'nickname': nickname,
      'role': role,
    };
    if (email != null && email.isNotEmpty) {
      data['email'] = email;
    }

    final result = await AppSupabase.client
        .from('profiles')
        .insert(data).select().single();

    return UserProfile.fromJson(result);
  }

  /// 登录已有用户（更新本地存储）
  Future<UserProfile> loginExistingUser(UserProfile profile) async {
    // 保存到本地
    await LocalUserStorage.saveUser(
      userId: profile.id,
      nickname: profile.nickname,
      role: profile.role,
      email: profile.email,
    );
    _currentUserId = profile.id;
    return profile;
  }

  /// 保存用户资料
  Future<UserProfile> saveProfile({
    required String nickname,
    required String role,
    String? avatarUrl,
    String? email,
  }) async {
    final id = _currentUserId;
    if (id == null) {
      throw Exception('当前用户未登录');
    }

    final data = <String, dynamic>{
      'id': id,
      'nickname': nickname,
      'role': role,
    };
    if (avatarUrl != null) {
      data['avatar_url'] = avatarUrl;
    }
    if (email != null && email.isNotEmpty) {
      data['email'] = email;
    }

    final result = await AppSupabase.client
        .from('profiles')
        .upsert(data).select().single();

    // 更新本地存储
    await LocalUserStorage.saveUser(
      userId: id,
      nickname: nickname,
      role: role,
      email: email,
    );

    return UserProfile.fromJson(result);
  }

  /// 上传用户头像
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String userId,
  }) async {
    final path = 'avatars/$userId.jpg';
    await AppSupabase.client.storage.from('dish-images').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    return AppSupabase.client.storage.from('dish-images').getPublicUrl(path);
  }

  /// 退出登录
  Future<void> logout() async {
    await LocalUserStorage.clearUser();
    _currentUserId = null;
  }

  /// 绑定对象
  /// 通过昵称或邮箱查找用户并绑定
  /// 返回被绑定的用户资料
  Future<UserProfile> bindPartner(String input) async {
    final id = _currentUserId;
    if (id == null) {
      throw Exception('当前用户未登录');
    }

    // 查找要绑定的用户
    final partner = await findUserByNameOrEmail(input);
    if (partner == null) {
      throw Exception('未找到该用户，请确认昵称或邮箱是否正确');
    }

    // 不能绑定自己
    if (partner.id == id) {
      throw Exception('不能绑定自己');
    }

    // 不能绑定已有对象的人
    if (partner.hasPartner) {
      throw Exception('该用户已绑定其他对象');
    }

    // 更新当前用户的 partner_id 和 partner_nickname
    await AppSupabase.client
        .from('profiles')
        .update({
          'partner_id': partner.id,
          'partner_nickname': partner.nickname,
        })
        .eq('id', id);

    // 同时更新对方的资料（双向绑定）
    await AppSupabase.client
        .from('profiles')
        .update({
          'partner_id': id,
          'partner_nickname': (await fetchMyProfile())?.nickname ?? '对象',
        })
        .eq('id', partner.id);

    // 返回更新后的用户资料
    final updated = await fetchMyProfile();
    return updated!;
  }

  /// 解绑对象
  Future<void> unbindPartner() async {
    final id = _currentUserId;
    if (id == null) {
      throw Exception('当前用户未登录');
    }

    // 获取当前用户资料
    final myProfile = await fetchMyProfile();
    if (myProfile == null || !myProfile.hasPartner) {
      throw Exception('当前没有绑定对象');
    }

    final partnerId = myProfile.partnerId!;

    // 清空当前用户的 partner_id
    await AppSupabase.client
        .from('profiles')
        .update({
          'partner_id': null,
          'partner_nickname': null,
        })
        .eq('id', id);

    // 同时清空对方的资料
    await AppSupabase.client
        .from('profiles')
        .update({
          'partner_id': null,
          'partner_nickname': null,
        })
        .eq('id', partnerId);
  }
}

