/// Supabase 客户端配置
/// 
/// 功能：
/// 1. AppSupabaseConfig：提供 Supabase URL 和 ANON_KEY（仅从 .env 文件读取）
/// 2. AppSupabase：全局 SupabaseClient 单例访问器
/// 
/// 使用方式：通过 AppSupabase.client 访问数据库操作
/// 
/// 要求：.env 文件中必须包含 SUPABASE_URL 和 SUPABASE_ANON_KEY

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AppSupabaseConfig {
  AppSupabaseConfig._();

  /// 从 .env 文件获取 Supabase URL
  /// 必须在 .env 文件中配置 SUPABASE_URL
  static String get url {
    final value = dotenv.env['SUPABASE_URL'];
    if (value == null || value.isEmpty) {
      throw Exception('请在 .env 文件中配置 SUPABASE_URL');
    }
    return value;
  }

  /// 从 .env 文件获取 Supabase ANON_KEY
  /// 必须在 .env 文件中配置 SUPABASE_ANON_KEY
  static String get anonKey {
    final value = dotenv.env['SUPABASE_ANON_KEY'];
    if (value == null || value.isEmpty) {
      throw Exception('请在 .env 文件中配置 SUPABASE_ANON_KEY');
    }
    return value;
  }

}

class AppSupabase {
  AppSupabase._();

  static final SupabaseClient client = Supabase.instance.client;
}
