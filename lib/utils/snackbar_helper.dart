/// 通用 SnackBar 样式辅助
///
/// 使用方式：
/// - success: SnackBarHelper.show(context, '操作成功', isSuccess: true)
/// - error: SnackBarHelper.show(context, '操作失败', isError: true)
/// - info: SnackBarHelper.show(context, '提示信息')

import 'package:flutter/material.dart';

class SnackBarHelper {
  /// 显示美化后的 SnackBar
  ///
  /// [message] 提示内容
  /// [isSuccess] 是否为成功提示（绿色背景 + 勾号图标）
  /// [isError] 是否为错误提示（粉色背景 + 叉号图标）
  /// [isWarning] 是否为警告提示（橙色背景）
  /// 默认无图标，灰色背景
  static void show(
    BuildContext context,
    String message, {
    bool isSuccess = false,
    bool isError = false,
    bool isWarning = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_outline
                  : (isError
                      ? Icons.error_outline
                      : (isWarning ? Icons.warning_amber_outlined : Icons.info_outline)),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF4CAF50)
            : (isError
                ? const Color(0xFFE85D9A)
                : (isWarning ? const Color(0xFFFF9800) : const Color(0xFF666666))),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  /// 显示成功提示
  static void success(BuildContext context, String message) {
    show(context, message, isSuccess: true);
  }

  /// 显示错误提示
  static void error(BuildContext context, String message) {
    show(context, message, isError: true);
  }

  /// 显示警告提示
  static void warning(BuildContext context, String message) {
    show(context, message, isWarning: true);
  }

  /// 显示普通提示
  static void info(BuildContext context, String message) {
    show(context, message);
  }
}
