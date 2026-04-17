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
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/supabase_client.dart';
import 'services/jpush_service.dart';

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
  runApp(const DujiaYushanfangApp());

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

  // 初始化极光推送
  try {
    await JPushService().init();
    debugPrint('极光推送 初始化完成');
  } catch (error) {
    debugPrint('极光推送 初始化失败：$error');
  }
}


