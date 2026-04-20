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

    final summaryHtml = items.map((item) {
      final spec = item.specSummary.isEmpty ? '' : '<span style="color:#666;font-size:12px;">（${item.specSummary}）</span>';
      return '''
        <tr>
          <td style="padding:10px;border-bottom:1px solid #eee;">${item.dish.name}$spec</td>
          <td style="padding:10px;border-bottom:1px solid #eee;text-align:center;">x${item.quantity}</td>
          <td style="padding:10px;border-bottom:1px solid #eee;text-align:right;">${item.unitPrice.toStringAsFixed(2)}</td>
          <td style="padding:10px;border-bottom:1px solid #eee;text-align:right;color:#e74c3c;font-weight:bold;">${item.subtotal.toStringAsFixed(2)}</td>
        </tr>
      ''';
    }).join('');

    final now = DateTime.now();
    final dateStr = '${now.year}年${now.month}月${now.day}日 ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;background-color:#f5f5f5;font-family:'Microsoft YaHei','PingFang SC',sans-serif;">
  <div style="max-width:600px;margin:20px auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,0.1);">
    <!-- 头部 -->
    <div style="background:linear-gradient(135deg,#e74c3c 0%,#c0392b 100%);padding:30px;text-align:center;">
      <h1 style="margin:0;color:#fff;font-size:24px;font-weight:bold;">🍽️ 御膳房新订单</h1>
      <p style="margin:10px 0 0;color:rgba(255,255,255,0.9);font-size:14px;">您的另一半刚刚下单啦~</p>
    </div>
    
    <!-- 订单信息 -->
    <div style="padding:25px;">
      <h2 style="margin:0 0 15px;font-size:16px;color:#333;border-left:4px solid #e74c3c;padding-left:10px;">📋 订单信息</h2>
      <div style="background:#f8f9fa;border-radius:8px;padding:15px;">
        <table style="width:100%;border-collapse:collapse;">
          <tr>
            <td style="padding:8px 0;color:#666;font-size:13px;">订单编号</td>
            <td style="padding:8px 0;text-align:right;color:#333;font-weight:bold;font-size:13px;">#$orderId</td>
          </tr>
          <tr>
            <td style="padding:8px 0;color:#666;font-size:13px;">下单人</td>
            <td style="padding:8px 0;text-align:right;color:#333;font-weight:bold;font-size:13px;">$nickname 💕</td>
          </tr>
          <tr>
            <td style="padding:8px 0;color:#666;font-size:13px;">下单时间</td>
            <td style="padding:8px 0;text-align:right;color:#333;font-size:13px;">$dateStr</td>
          </tr>
        </table>
      </div>
    </div>
    
    <!-- 商品明细 -->
    <div style="padding:0 25px 25px;">
      <h2 style="margin:0 0 15px;font-size:16px;color:#333;border-left:4px solid #e74c3c;padding-left:10px;">🛒 订单明细</h2>
      <table style="width:100%;border-collapse:collapse;background:#fff;border:1px solid #eee;border-radius:8px;overflow:hidden;">
        <thead>
          <tr style="background:#f8f9fa;">
            <th style="padding:12px 10px;text-align:left;font-size:13px;color:#666;">菜品</th>
            <th style="padding:12px 10px;text-align:center;font-size:13px;color:#666;">数量</th>
            <th style="padding:12px 10px;text-align:right;font-size:13px;color:#666;">单价</th>
            <th style="padding:12px 10px;text-align:right;font-size:13px;color:#666;">小计</th>
          </tr>
        </thead>
        <tbody>
          $summaryHtml
        </tbody>
        <tfoot>
          <tr style="background:#fff5f5;">
            <td colspan="3" style="padding:15px 10px;text-align:right;font-size:15px;color:#333;font-weight:bold;">合计积分</td>
            <td style="padding:15px 10px;text-align:right;font-size:18px;color:#e74c3c;font-weight:bold;">$totalPoints</td>
          </tr>
        </tfoot>
      </table>
    </div>
    
    <!-- 备注 -->
    ${(note != null && note.trim().isNotEmpty) ? '''
    <div style="padding:0 25px 25px;">
      <h2 style="margin:0 0 15px;font-size:16px;color:#333;border-left:4px solid #e74c3c;padding-left:10px;">📝 备注</h2>
      <div style="background:#fffbe6;border:1px solid #ffe58f;border-radius:8px;padding:12px 15px;">
        <span style="color:#faad14;margin-right:8px;">⚠️</span>
        <span style="color:#666;font-size:14px;">$note</span>
      </div>
    </div>
    ''' : ''}
    
    <!-- 底部 -->
    <div style="background:#f8f9fa;padding:20px;text-align:center;border-top:1px solid #eee;">
      <p style="margin:0;color:#999;font-size:12px;">— 来自御膳房 💌 —</p>
    </div>
  </div>
</body>
</html>
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
      ..subject = '🍽️ 御膳房新订单通知'
      ..html = htmlBody;

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
