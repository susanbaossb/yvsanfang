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
  }) async {
    final id = currentUserId;
    final result = await AppSupabase.client
        .from('profiles')
        .upsert({'id': id, 'nickname': nickname, 'role': role}).select().single();

    return UserProfile.fromJson(result);
  }
}
