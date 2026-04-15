import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import '../models/user_profile.dart';

class AuthService {
  Future<void> ensureSignedIn() async {
    final session = AppSupabase.client.auth.currentSession;
    if (session != null) return;

    try {
      await AppSupabase.client.auth.signInAnonymously();
      debugPrint('Auth: signInAnonymously success');
    } on AuthException catch (e, st) {
      debugPrint('AuthException on signInAnonymously: ${e.message} (status: ${e.statusCode})');
      debugPrintStack(stackTrace: st);
      if (e.statusCode == '422') {
        throw Exception('初始化失败 422：请到 Supabase 控制台开启 Anonymous Sign-ins（Auth > Providers > Anonymous）');
      }
      throw Exception('初始化失败：${e.message} (status: ${e.statusCode})');
    } catch (e, st) {
      debugPrint('Unknown auth init error: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }


  String get currentUserId {
    final user = AppSupabase.client.auth.currentUser;
    if (user == null) {
      throw Exception('当前用户未登录');
    }
    return user.id;
  }

  String? get currentUserEmail {
    return AppSupabase.client.auth.currentUser?.email;
  }

  Future<UserProfile?> fetchMyProfile() async {
    final id = currentUserId;
    final result = await AppSupabase.client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (result == null) {
      return null;
    }

    return UserProfile.fromJson(result);
  }

  Future<UserProfile> saveProfile({
    required String nickname,
    required String role,
    String? avatarUrl,
    String? email,
  }) async {
    final id = currentUserId;
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

    return UserProfile.fromJson(result);
  }

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

  Future<void> bindEmail(String email) async {
    await AppSupabase.client.auth.updateUser(
      UserAttributes(data: {'email': email}),
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    await AppSupabase.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
}
