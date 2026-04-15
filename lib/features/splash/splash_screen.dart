/// 启动页/闪屏页
/// 
/// 功能：
/// 1. 显示品牌 Logo 或启动图（image/banner.png）
/// 2. 停留 2 秒后自动跳转到登录页
/// 3. 作为应用入口，首先展示给用户
/// 
/// 注意：此页面在 main.dart 中先于 Supabase 初始化显示

import 'package:flutter/material.dart';

import '../auth/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    // 显示开屏图 2 秒
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFFFF6FA),
        child: Center(
          child: Image.asset(
            'image/banner.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
