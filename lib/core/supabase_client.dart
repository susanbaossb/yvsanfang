/// Supabase 客户端配置
/// 
/// 功能：
/// 1. AppSupabaseConfig：提供 Supabase URL 和 ANON_KEY
///    - 优先从 .env 文件读取
///    - 其次从 dart-define 读取
///    - 最后使用默认值
/// 2. AppSupabase：全局 SupabaseClient 单例访问器
/// 
/// 使用方式：通过 AppSupabase.client 访问数据库操作

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AppSupabaseConfig {
  AppSupabaseConfig._();

  static String get url {
    final fromDotenv = dotenv.env['SUPABASE_URL'];
    if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;

    return const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://yydbcbhahqqjdfbzbqlh.supabase.co',
    );
  }

  static String get anonKey {
    final fromDotenv = dotenv.env['SUPABASE_ANON_KEY'];
    if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;

    return const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl5ZGJjYmhhaHFxamRmYnpicWxoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUxMDE2ODEsImV4cCI6MjA5MDY3NzY4MX0.jdXuQp0D0740BZTHtBOc6XZ5LfWV743MRSBOZv4U36I',
    );
  }

}

class AppSupabase {
  AppSupabase._();

  static final SupabaseClient client = Supabase.instance.client;
}
