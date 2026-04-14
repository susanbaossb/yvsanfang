import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import 'order_service.dart';

class OrderEmailService {
  static const String _defaultReceiver = '1951345484@qq.com';

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
    final receiver = (dotenv.env['ORDER_NOTIFY_EMAIL']?.trim().isNotEmpty ?? false)
        ? dotenv.env['ORDER_NOTIFY_EMAIL']!.trim()
        : _defaultReceiver;

    if (senderAccount.isEmpty || authCode.isEmpty) {
      throw Exception('未配置 QQ 发件账号，请在 .env 设置 QQ_EMAIL_ACCOUNT / QQ_EMAIL_AUTH_CODE');
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
下单人ID：$userId
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
      ..recipients.add(receiver)
      ..subject = '御膳房新订单通知 #$orderId'
      ..text = body;

    await send(message, smtpServer);
  }
}
