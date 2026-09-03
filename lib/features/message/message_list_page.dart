// 消息中心：外层列表，聚合「活动消息 / 订单消息 / 与对象的私聊」
// 入口：底部导航「消息」

import 'package:flutter/material.dart';

import '../activity/notification_page.dart';
import 'message_page.dart';
import 'order_message_page.dart';

class MessageListPage extends StatelessWidget {
  const MessageListPage({
    super.key,
    required this.userId,
    required this.activityUnread,
    required this.orderUnread,
    required this.chatUnread,
    required this.hasPartner,
    required this.partnerNickname,
    required this.partnerId,
    this.onActivitySeen,
    this.onOrderSeen,
    this.onChatRead,
    this.onGoBind,
  });

  final String userId;
  final int activityUnread;
  final int orderUnread;
  final int chatUnread;
  final bool hasPartner;
  final String partnerNickname;
  final String partnerId;
  final VoidCallback? onActivitySeen;
  final VoidCallback? onOrderSeen;
  final VoidCallback? onChatRead;
  final VoidCallback? onGoBind;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionLabel('系统消息'),
        _SystemMessageBlock(
          children: [
            _MessageRow(
              icon: Icons.campaign_outlined,
              iconColor: const Color(0xFFE85D9A),
              title: '活动消息',
              subtitle: '任务提交与审核提醒',
              unread: activityUnread,
              dense: true,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NotificationPage(
                      userId: userId,
                      initialTab: 0,
                      onMyResultsRead: onActivitySeen,
                    ),
                  ),
                );
                onActivitySeen?.call();
              },
            ),
            _MessageRow(
              icon: Icons.receipt_long_outlined,
              iconColor: const Color(0xFF3FA9F5),
              title: '订单消息',
              subtitle: 'TA 的订单动态',
              unread: orderUnread,
              dense: true,
              onTap: () async {
                if (!hasPartner || partnerId.isEmpty) {
                  onGoBind?.call();
                  return;
                }
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OrderMessagePage(partnerId: partnerId),
                  ),
                );
                onOrderSeen?.call();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _SectionLabel('私聊'),
        if (hasPartner)
          _MessageRow(
            icon: Icons.chat_bubble_outline,
            iconColor: const Color(0xFF7C5CFF),
            title: '与 ${partnerNickname.isEmpty ? 'TA' : partnerNickname} 的聊天',
            subtitle: '和对象的专属对话',
            unread: chatUnread,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MessagePage(userId: userId),
                ),
              );
              onChatRead?.call();
            },
          )
        else
          _MessageRow(
            icon: Icons.chat_bubble_outline,
            iconColor: Colors.grey,
            title: '未绑定对象',
            subtitle: '去「我的」绑定后即可聊天',
            unread: 0,
            showChevron: false,
            onTap: () => onGoBind?.call(),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4, top: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.unread,
    required this.onTap,
    this.showChevron = true,
    this.dense = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int unread;
  final VoidCallback onTap;
  final bool showChevron;

  // 在 _SystemMessageBlock 内渲染时为 true：去掉自身 Card/外边距/自身 ListTile 的上下内边距
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      onTap: onTap,
      // dense 模式下压扁上下内边距，让相邻行紧贴分隔线
      contentPadding: dense ? const EdgeInsets.symmetric(horizontal: 16) : null,
      minVerticalPadding: dense ? 6 : null,
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.12),
        child: Icon(icon, color: iconColor),
      ),
      title:
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (unread > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$unread',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12)),
            ),
          if (unread > 0 && showChevron) const SizedBox(width: 4),
          if (showChevron) const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );

    if (dense) return tile;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: tile,
    );
  }
}

/// 把多条相邻消息条目合成一个圆角卡片，中间用细分隔线连接，看起来像一组。
class _SystemMessageBlock extends StatelessWidget {
  const _SystemMessageBlock({required this.children});

  final List<_MessageRow> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                const Divider(height: 1, indent: 64, endIndent: 16),
            ],
          ],
        ),
      ),
    );
  }
}
