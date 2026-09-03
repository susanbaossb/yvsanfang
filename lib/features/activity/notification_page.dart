/// 消息与提醒页面
///
/// 功能：
/// 1. 待我审核：绑定对象提交的任务（文字 / 图片 / 视频 / 语音）会在这里出现
///    - 通过：按任务积分给对方加积分，对方任务状态变为「已完成」
///    - 不通过：填写原因后驳回，对方可继续完成任务，但不会获得积分
/// 2. 我的消息：我提交的任务被审核的结果通知
///
/// 入口：我的 → 消息通知

import 'package:flutter/material.dart';

import '../../models/activity_task.dart';
import '../../services/activity_task_service.dart';
import '../../services/auth_service.dart';
import '../../utils/snackbar_helper.dart';
import 'submission_detail_page.dart';
import 'task_review_card.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({
    super.key,
    required this.userId,
    this.initialTab = 0,
    this.onMyResultsRead,
  });

  /// 当前登录用户 ID
  final String userId;

  /// 初始打开的 Tab（0=待我审核，1=我的消息）
  final int initialTab;

  /// 进入「我的消息」并标记已读后回调（用于刷新首页角标）
  final VoidCallback? onMyResultsRead;

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  final _service = ActivityTaskService();
  final _authService = AuthService();

  late final TabController _tabController;

  List<TaskSubmission> _pending = [];
  List<TaskSubmission> _results = [];
  bool _loading = true;
  bool _saving = false;
  bool _hasPartner = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabController.addListener(_onTabChanged);
    _load();
    // 直接进入「我的消息」时，监听不会触发，需主动标记已读
    if (widget.initialTab == 1) _markMyResultsRead();
  }

  void _onTabChanged() {
    // 切到「我的消息」(index=1) 且动画结束，标记已读
    if (_tabController.index == 1 && !_tabController.indexIsChanging) {
      _markMyResultsRead();
    }
  }

  Future<void> _markMyResultsRead() async {
    widget.onMyResultsRead?.call();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // 重新拉取资料，保证刚绑定对象后即可收到提醒
      await _authService.initCurrentUser();
      final profile = await _authService.fetchMyProfile();
      final partnerId = profile?.partnerId;

      final hasPartner = partnerId != null && partnerId.isNotEmpty;
      final pending = hasPartner
          ? await _service.fetchPartnerPending(partnerId)
          : <TaskSubmission>[];
      final results = await _service.fetchMyResults(widget.userId);

      if (!mounted) return;
      setState(() {
        _hasPartner = hasPartner;
        _pending = pending;
        _results = results;
      });
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.error(context, '加载失败');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 审核：通过后按任务积分给对方加积分
  Future<void> _review(TaskSubmission submission, bool approved) async {
    String? reason;
    if (!approved) {
      final inputController = TextEditingController();
      reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('不通过原因'),
          content: TextField(
            controller: inputController,
            maxLines: 3,
            minLines: 2,
            decoration: const InputDecoration(
              hintText: '告诉 TA 哪里还不符合要求（选填）',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(inputController.text.trim()),
              child: const Text('确认驳回'),
            ),
          ],
        ),
      );
      if (reason == null) return;
    }

    setState(() => _saving = true);
    try {
      final newPoints = await _service.reviewSubmission(
        submission: submission,
        approved: approved,
        rejectReason: (reason == null || reason.isEmpty) ? null : reason,
      );
      if (!mounted) return;
      SnackBarHelper.success(
        context,
        approved
            ? '已通过，${submission.nickname} 获得 $newPoints 积分'
            : '已驳回，TA 可以重新完成任务',
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.error(
          context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息与提醒'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: _pending.isEmpty
                  ? '待我审核'
                  : '待我审核 (${_pending.length})',
            ),
            const Tab(text: '我的消息'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReviewTab(),
                _buildResultTab(),
              ],
            ),
    );
  }

  Widget _buildReviewTab() {
    if (!_hasPartner) {
      return _buildEmpty(
        icon: Icons.people_outline,
        text: '个人主页绑定对象后，TA 完成任务你就会在这里收到提醒',
      );
    }
    if (_pending.isEmpty) {
      return _buildEmpty(
        icon: Icons.notifications_none,
        text: '暂无待审核的任务提醒',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: _pending.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) => TaskReviewCard(
          submission: _pending[index],
          saving: _saving,
          onReview: _review,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SubmissionDetailPage(
                submission: _pending[index],
                onReview: _review,
                saving: _saving,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultTab() {
    // 合并「任务审核结果」与「对方订单事件」，按事件时间倒序排列
    final items = <_MessageItem>[];
    for (final r in _results) {
      items.add(_MessageItem(
        time: r.reviewedAt ?? r.createdAt ?? DateTime(0),
        widget: _buildResultCard(r),
      ));
    }
    items.sort((a, b) => b.time.compareTo(a.time));

    if (items.isEmpty) {
      return _buildEmpty(
        icon: Icons.inbox_outlined,
        text: '暂无消息，你提交的任务被审核后会在这里显示提醒',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) => items[index].widget,
      ),
    );
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

  Widget _buildResultCard(TaskSubmission item) {
    final approved = item.isApproved;
    final reason = item.rejectReason;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SubmissionDetailPage(submission: item),
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor:
                approved ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
          child: Icon(
            approved ? Icons.check : Icons.close,
            color: approved ? Colors.green : Colors.redAccent,
          ),
        ),
        title: Text(
          item.taskTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            approved
                ? '审核通过，获得 ${item.taskPoints} 积分'
                : '未通过：${(reason != null && reason.isNotEmpty) ? reason : '未填写原因'}，可以继续完成任务',
          ),
        ),
        trailing: Text(
          _formatTime(item.reviewedAt ?? item.createdAt ?? DateTime.now()),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ),
      ),
    );
  }

  Widget _buildEmpty({required IconData icon, required String text}) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 120, 32, 24),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: const Color(0xFFFFB3D1)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageItem {
  const _MessageItem({required this.time, required this.widget});
  final DateTime time;
  final Widget widget;
}
