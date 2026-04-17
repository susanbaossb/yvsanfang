/// 极光推送服务
///
/// 功能：
/// 1. 初始化极光推送 SDK
/// 2. 设置别名（用于精准推送）
/// 3. 处理接收到的推送消息
///
/// 使用方式：
/// - JPushService().init() 在 main.dart 中初始化
/// - JPushService().setAlias(userId) 用户登录后设置别名
/// - JPushService().deleteAlias() 用户退出时删除别名
///
/// 消息回调（需设置 onMessageReceived）：
/// - onReceiveNotification: 通知送达时触发
/// - onOpenNotification: 点击通知打开应用时触发
/// - onReceiveMessage: 接收自定义消息时触发
///
/// 配置：.env 文件中需要配置 JPUSH_APPKEY

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jpush_flutter/jpush_flutter.dart';

class JPushService {
  static final JPushService _instance = JPushService._internal();
  factory JPushService() => _instance;
  JPushService._internal();

  final JPush _jpush = JPush();

  /// 通知送达回调
  Function(Map<String, dynamic>)? onReceiveNotification;

  /// 点击通知回调
  Function(Map<String, dynamic>)? onOpenNotification;

  /// 自定义消息回调
  Function(Map<String, dynamic>)? onReceiveMessage;

  /// 初始化极光推送
  Future<void> init() async {
    // 从 .env 获取 AppKey
    final appKey = dotenv.env['JPUSH_APPKEY'];
    if (appKey == null || appKey.isEmpty) {
      throw Exception('请在 .env 文件中配置 JPUSH_APPKEY');
    }

    // 先设置事件监听
    _jpush.addEventHandler(
      onReceiveNotification: (Map<String, dynamic> message) async {
        debugPrint('【JPush】收到通知: $message');
        onReceiveNotification?.call(message);
      },
      onOpenNotification: (Map<String, dynamic> message) async {
        debugPrint('【JPush】点击通知: $message');
        onOpenNotification?.call(message);
      },
      onReceiveMessage: (Map<String, dynamic> message) async {
        debugPrint('【JPush】收到自定义消息: $message');
        onReceiveMessage?.call(message);
      },
    );

    // 初始化 SDK
    _jpush.setup(
      appKey: appKey,
      channel: "developer_default",
      production: kReleaseMode,  // 生产环境设为 true
      debug: !kReleaseMode,      // 调试模式仅在开发环境开启
    );

    debugPrint('【JPush】初始化完成');

    // 获取 Registration ID（设备唯一标识）
    try {
      final rid = await _jpush.getRegistrationID();
      debugPrint('【JPush】Registration ID: $rid');
    } catch (e) {
      debugPrint('【JPush】获取 Registration ID 失败: $e');
    }
  }

  /// 设置别名（用于精准推送给指定用户）
  /// [alias] 通常为用户 ID，会被处理为符合极光规范的格式
  Future<void> setAlias(String alias) async {
    try {
      // 极光别名规范：只能包含字母、数字、下划线、连字符，最长40字节
      // 将 UUID 中的连字符移除，确保格式正确
      final validAlias = alias.replaceAll('-', '').toLowerCase();
      await _jpush.setAlias(validAlias);
      debugPrint('【JPush】设置别名成功: $validAlias');
    } catch (e) {
      debugPrint('【JPush】设置别名失败: $e');
    }
  }

  /// 删除别名
  Future<void> deleteAlias() async {
    try {
      await _jpush.deleteAlias();
      debugPrint('【JPush】删除别名成功');
    } catch (e) {
      debugPrint('【JPush】删除别名失败: $e');
    }
  }

  /// 添加标签（用于分组推送）
  Future<void> addTags(List<String> tags) async {
    try {
      await _jpush.addTags(tags);
      debugPrint('【JPush】添加标签成功: $tags');
    } catch (e) {
      debugPrint('【JPush】添加标签失败: $e');
    }
  }

  /// 设置角标（Android）
  Future<void> setBadge(int badge) async {
    try {
      await _jpush.setBadge(badge);
    } catch (e) {
      debugPrint('【JPush】设置角标失败: $e');
    }
  }

  /// 清空所有通知
  Future<void> clearAllNotifications() async {
    try {
      await _jpush.clearAllNotifications();
    } catch (e) {
      debugPrint('【JPush】清空通知失败: $e');
    }
  }

  /// 停止推送
  Future<void> stopPush() async {
    try {
      await _jpush.stopPush();
    } catch (e) {
      debugPrint('【JPush】停止推送失败: $e');
    }
  }

  /// 恢复推送
  Future<void> resumePush() async {
    try {
      await _jpush.resumePush();
    } catch (e) {
      debugPrint('【JPush】恢复推送失败: $e');
    }
  }
}
