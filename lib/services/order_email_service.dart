/// 订单邮件通知服务
/// 
/// 功能：
/// - sendOrderEmail: 下单成功后发送邮件通知
/// 
/// 邮件内容包含：订单号、下单人昵称、下单时间、订单明细、合计积分、备注
/// 使用 QQ 邮箱 SMTP 发送，需要在 .env 配置 QQ_EMAIL_ACCOUNT 和 QQ_EMAIL_AUTH_CODE

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import 'order_service.dart';

class OrderEmailService {
  /// 发送订单邮件通知
  /// 优先发送给绑定对象的邮箱，如果没有绑定对象或没有邮箱则不发送
  Future<void> sendOrderEmail({
    required String orderId,
    required String userId,
    required String nickname,
    required List<CartItem> items,
    required int totalPoints,
    String? note,
  }) async {
    final senderAccount = dotenv.env['QQ_EMAIL_ACCOUNT']?.trim() ?? '';
    final authCode = dotenv.env['QQ_EMAIL_AUTH_CODE']?.trim() ?? '';

    if (senderAccount.isEmpty || authCode.isEmpty) {
      debugPrint('未配置 QQ 发件账号，跳过邮件发送');
      return;
    }

    // 获取绑定对象的邮箱
    String? partnerEmail;
    try {
      partnerEmail = await _getPartnerEmail(userId);
    } catch (e) {
      debugPrint('获取绑定对象邮箱失败：$e');
    }

    // 如果没有绑定对象或没有邮箱，静默跳过
    if (partnerEmail == null || partnerEmail.trim().isEmpty) {
      debugPrint('没有绑定对象或绑定对象未设置邮箱，跳过邮件发送');
      return;
    }

    final smtpHost = dotenv.env['QQ_SMTP_HOST']?.trim().isNotEmpty == true
        ? dotenv.env['QQ_SMTP_HOST']!.trim()
        : 'smtp.qq.com';
    final smtpPort = int.tryParse(dotenv.env['QQ_SMTP_PORT'] ?? '') ?? 465;

    final summaryLines = items.map((item) {
      final spec = item.specSummary.isEmpty ? '' : '（${item.specSummary}）';
      return '- ${item.dish.name}$spec x${item.quantity}，单价 ${item.unitPrice.toStringAsFixed(2)}，小计 ${item.subtotal.toStringAsFixed(2)}';
    }).join('\n');

    final now = DateTime.now();
    final body = '''
【御膳房】有新订单

订单号：$orderId
下单人昵称：$nickname
下单时间：${now.toIso8601String()}

订单明细：
$summaryLines

合计积分：$totalPoints
备注：${(note != null && note.trim().isNotEmpty) ? note.trim() : '无'}
''';

    final smtpServer = SmtpServer(
      smtpHost,
      port: smtpPort,
      ssl: smtpPort == 465,
      username: senderAccount,
      password: authCode,
    );

    final message = Message()
      ..from = Address(senderAccount, '御膳房订单通知')
      ..recipients.add(partnerEmail.trim())
      ..subject = '御膳房新订单通知 #$orderId'
      ..text = body;

    await send(message, smtpServer);
    debugPrint('订单邮件已发送给绑定对象：$partnerEmail');
  }

  /// 获取绑定对象的邮箱
  Future<String?> _getPartnerEmail(String userId) async {
    // 查询当前用户资料
    final profileResult = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (profileResult == null) return null;

    final profile = UserProfile.fromJson(profileResult);
    
    // 如果没有绑定对象，返回 null
    if (!profile.hasPartner || profile.partnerId == null) return null;

    // 查询绑定对象的资料
    final partnerResult = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', profile.partnerId!)
        .maybeSingle();

    if (partnerResult == null) return null;

    final partner = UserProfile.fromJson(partnerResult);
    return partner.email;
  }
}
