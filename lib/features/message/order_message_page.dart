// 订单消息列表：展示绑定对象（TA）的订单动态，点进查看订单详情
// 入口：消息中心 → 订单消息

import 'package:flutter/material.dart';

import '../../models/order_summary.dart';
import '../../services/order_service.dart';
import '../../utils/snackbar_helper.dart';
import '../activity/order_detail_page.dart';

class OrderMessagePage extends StatefulWidget {
  const OrderMessagePage({super.key, required this.partnerId});

  final String partnerId;

  @override
  State<OrderMessagePage> createState() => _OrderMessagePageState();
}

class _OrderMessagePageState extends State<OrderMessagePage> {
  final _orderService = OrderService();
  List<OrderSummary> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _orderService.fetchPartnerOrders(widget.partnerId);
      // 按事件时间倒序，最新订单在最上方
      list.sort((a, b) => b.eventTime.compareTo(a.eventTime));
      if (!mounted) return;
      setState(() {
        _orders = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (mounted) SnackBarHelper.error(context, '订单消息加载失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('订单消息')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(
                  child: Text('暂无订单消息', style: TextStyle(color: Colors.grey)),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildOrderCard(_orders[i]),
                  ),
                ),
    );
  }

  Widget _buildOrderCard(OrderSummary order) {
    final isDeleted = order.status == 'deleted';
    IconData icon;
    Color tint;
    String title;
    switch (order.status) {
      case 'completed':
        icon = Icons.check_circle_rounded;
        tint = Colors.green;
        title = '订单已完成';
      case 'cancelled':
        icon = Icons.cancel_rounded;
        tint = const Color(0xFFE58A00);
        title = '订单已取消';
      case 'deleted':
        icon = Icons.delete_rounded;
        tint = Colors.grey;
        title = '订单已删除';
      default:
        icon = Icons.shopping_bag_rounded;
        tint = const Color(0xFFE85D9A);
        title = '对方下了一笔新订单';
    }

    final dishSummary = order.items.isEmpty
        ? '暂无菜品'
        : order.items.map((e) => e.summary).join('，');
    final noteText =
        order.note != null && order.note!.isNotEmpty ? ' · ${order.note}' : '';

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OrderDetailPage(order: order),
          ),
        ),
        child: Opacity(
          opacity: isDeleted ? 0.6 : 1,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color.lerp(tint, Colors.white, 0.85),
              child: Icon(icon, color: tint),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dishSummary),
                  const SizedBox(height: 2),
                  Text(
                    '共 ${order.items.length} 件 · 积分${order.totalAmount.toStringAsFixed(0)}$noteText',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(order.eventTime),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Color.lerp(tint, Colors.white, 0.88),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _orderStatusText(order.status),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: tint,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _orderStatusText(String raw) {
    switch (raw) {
      case 'unfinished':
      case 'done':
        return '未完成';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      case 'deleted':
        return '已删除';
      default:
        return raw;
    }
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final hhmm =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (sameDay) return '今天 $hhmm';
    return '${local.month}月${local.day}日 $hhmm';
  }
}
