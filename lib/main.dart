/// 程序入口文件
///
/// 功能：
/// 1. 初始化 Flutter 环境（WidgetsFlutterBinding）
/// 2. 配置全局错误处理（FlutterError、PlatformDispatcher）
/// 3. 加载 .env 环境变量配置
/// 4. 先显示启动图（SplashScreen），后台初始化 Supabase
///
/// 作者：susanbao
/// 版本：1.0.0

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_console_panel/flutter_console_panel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
  };

  ErrorWidget.builder = (details) => Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('界面渲染异常：${details.exceptionAsString()}'),
          ),
        ),
      );

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught async error: $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };

  // 先加载 .env
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    debugPrint('.env 未加载');
  }

  // 先显示启动图（无需等待初始化）
  runApp(
    DebugPanel.init(
      child: const DujiaYushanfangApp(),
      config: const DebugConfig(
        // Release 模式下也可显示（仅调试用）
        showInReleaseMode: false,
        // 日志最多保留 2000 条
        maxLogEntries: 2000,
        // 网络记录最多保留 500 条
        maxNetworkEntries: 500,
      ),
    ),
  );

  // 初始化 Supabase
  try {
    await Supabase.initialize(
      url: AppSupabaseConfig.url,
      anonKey: AppSupabaseConfig.anonKey,
    );
    debugPrint('Supabase 初始化完成');
  } catch (error) {
    debugPrint('Supabase 初始化失败：$error');
  }
}


