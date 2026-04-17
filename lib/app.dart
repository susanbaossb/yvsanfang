/// 应用根组件
///
/// 功能：
/// 1. 定义应用主题（Material 3，粉色系配色）
/// 2. 配置全局组件样式（卡片、按钮、输入框、导航栏等）
/// 3. 设置启动页面为 SplashScreen
///
/// 配色方案：粉色系（#E85D9A 主色）搭配奶白背景

import 'package:flutter/material.dart';

import 'features/splash/splash_screen.dart';

class DujiaYushanfangApp extends StatelessWidget {
  const DujiaYushanfangApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFFF6FAE);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: const Color(0xFFE85D9A),
      secondary: const Color(0xFFFF9BC2),
      tertiary: const Color(0xFFFFC1DA),
      surface: const Color(0xFFFFFBFD),
    );

    return MaterialApp(
      title: '御膳房',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFFFF6FA),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFFFF6FA),
          foregroundColor: colorScheme.primary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: colorScheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: const Color(0xFFFFE1EE), width: 1),
          ),
        ),
        chipTheme: ChipThemeData(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: const Color(0xFFFFD3E6)),
          selectedColor: const Color(0xFFFFE5F1),
          backgroundColor: Colors.white,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            elevation: 0,
            shadowColor: const Color(0xFFFFA5CA).withValues(alpha: 0.3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side:
                BorderSide(color: colorScheme.primary.withValues(alpha: 0.35)),
            minimumSize: const Size(90, 42),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFFD5E7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFFD5E7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 68,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF8D2E5E)
                  : const Color(0xFF6A5B65),
            );
          }),
          indicatorColor: const Color(0xFFFFE5F1),
          backgroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
