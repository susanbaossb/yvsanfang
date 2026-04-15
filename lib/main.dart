import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    debugPrint('.env 未加载，回退到 dart-define / 默认配置');
  }

  // 先显示启动图（无需等待初始化）
  runApp(const DujiaYushanfangApp());

  // 后台初始化 Supabase
  try {
    await Supabase.initialize(
      url: AppSupabaseConfig.url,
      anonKey: AppSupabaseConfig.anonKey,
    );
    debugPrint('Supabase 初始化完成');
  } catch (error) {
    // 初始化失败，显示错误（此时 APP 已启动）
    debugPrint('Supabase 初始化失败：$error');
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message),
          ),
        ),
      ),
    );
  }
}


