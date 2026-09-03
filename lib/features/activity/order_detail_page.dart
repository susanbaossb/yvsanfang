/// 订单详情页
///
/// 从「消息与提醒 → 我的消息 / 订单 Tab」或「主页订单 Tab」点击订单卡片进入。

import 'package:flutter/material.dart';

import '../../models/order_summary.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final orderNo = order.orderNumber;
    final shortId =
        orderNo.length >= 8 ? orderNo.substring(0, 8) : orderNo;
    final info = _statusInfo(order.status);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F9),
      appBar: AppBar(
        title: const Text('订单详情'),
        backgroundColor: const Color(0xFFFBF6F9),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          // 状态头部（彩色背景但更柔和）
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [info.color, info.color.withValues(alpha: 0.78)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(info.icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '订单编号 $shortId',
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // —— 通用：每个分组是一个圆角浅灰容器，不再用白色 Card + 粉边/阴影 ——
          _Group(
            title: '基本信息',
            child: Column(
              children: [
                _Item(label: '完整订单号', value: orderNo, mono: true),
                _divider(),
                _Item(label: '下单时间', value: _format(order.createdAt)),
                if (order.updatedAt != null) ...[
                  _divider(),
                  _Item(label: '最近更新', value: _format(order.updatedAt!)),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          _Group(
            title: '商品明细',
            child: Column(
              children: [
                if (order.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('暂无菜品', style: TextStyle(color: Colors.grey)),
                  ),
                ...order.items.map((e) => _dish(e)),
                _divider(),
                _Item(
                  label: '合计积分',
                  value: order.totalAmount.toStringAsFixed(0),
                  valueStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE58A00),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _Group(
            title: '备注',
            child: Text(
              (order.note != null && order.note!.isNotEmpty) ? order.note! : '无',
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF5C4A56),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 一行菜品
  Widget _dish(OrderDishItem item) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: hasImage
                ? Image.network(
                    item.imageUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3A2A35),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '积分${item.unitPrice.toStringAsFixed(0)} × ${item.quantity}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '积分${(item.unitPrice * item.quantity).toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5C4A56),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 52,
      height: 52,
      color: const Color(0xFFFFF0F7),
      child: const Icon(Icons.ramen_dining, color: Color(0xFFE85D9A)),
    );
  }

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: const Color(0xFFEFE2EA),
      );

  _StatusInfo _statusInfo(String raw) {
    switch (raw) {
      case 'unfinished':
      case 'done':
        return _StatusInfo('未完成', Icons.receipt_long, const Color(0xFFE85D9A));
      case 'completed':
        return _StatusInfo('已完成', Icons.check_circle_rounded, Colors.green);
      case 'cancelled':
        return _StatusInfo('已取消', Icons.cancel_rounded, const Color(0xFFE58A00));
      case 'deleted':
        return _StatusInfo('已删除', Icons.delete_outline, Colors.grey);
      default:
        return _StatusInfo('未知', Icons.help_outline, Colors.grey);
    }
  }

  String _format(DateTime time) {
    final local = time.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusInfo {
  const _StatusInfo(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

// 分组容器：去掉了粉边/阴影，整体更克制
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8D7C85),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 12, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

// 一行 label / value（无外边距，交给容器控制）
class _Item extends StatelessWidget {
  const _Item({
    required this.label,
    required this.value,
    this.valueStyle,
    this.mono = false,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF8D7C85)),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: valueStyle ??
                TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF3A2A35),
                  fontFamily: mono ? 'monospace' : null,
                ),
          ),
        ),
      ],
    );
  }
}