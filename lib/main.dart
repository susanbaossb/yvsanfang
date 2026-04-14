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


  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    debugPrint('.env 未加载，回退到 dart-define / 默认配置');
  }

  try {
    await Supabase.initialize(
      url: AppSupabaseConfig.url,
      anonKey: AppSupabaseConfig.anonKey,
    );
  } catch (error) {

    runApp(_StartupErrorApp(message: 'Supabase 初始化失败：$error'));
    return;
  }

  runApp(const DujiaYushanfangApp());
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


