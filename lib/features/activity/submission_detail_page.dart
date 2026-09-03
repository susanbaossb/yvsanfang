/// 任务提交详情页（活动完成）
///
/// 从「消息与提醒」点击进入：
/// - 待我审核：可在此直接通过 / 驳回（onReview 由外部传入）
/// - 我的消息：只读展示审核结果与驳回原因

import 'package:flutter/material.dart';

import '../../models/activity_task.dart';
import 'submission_content.dart';

class SubmissionDetailPage extends StatefulWidget {
  const SubmissionDetailPage({
    super.key,
    required this.submission,
    this.onReview,
    this.saving = false,
  });

  final TaskSubmission submission;

  /// 传入后，待审核状态下底部显示「通过 / 不通过」按钮
  final Future<void> Function(TaskSubmission, bool)? onReview;

  /// 初始审核中状态（由消息列表的全局 saving 透传）
  final bool saving;

  @override
  State<SubmissionDetailPage> createState() => _SubmissionDetailPageState();
}

class _SubmissionDetailPageState extends State<SubmissionDetailPage> {
  late bool _saving;

  @override
  void initState() {
    super.initState();
    _saving = widget.saving;
  }

  Future<void> _handleReview(bool approved) async {
    final onReview = widget.onReview;
    if (onReview == null) return;
    setState(() => _saving = true);
    try {
      await onReview(widget.submission, approved);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败：${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.submission;
    final statusInfo = _statusInfo(s.status);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6F9),
      appBar: AppBar(
        title: const Text('任务详情'),
        backgroundColor: const Color(0xFFFBF6F9),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          // 顶部：头像 + 昵称 + 积分 + 状态胶囊
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFFFF0F7),
                  child: Text(
                    s.nickname.isNotEmpty ? s.nickname.substring(0, 1) : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE85D9A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.nickname,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3A2A35),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '+${s.taskPoints} 积分',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE58A00),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusInfo.bg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              statusInfo.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusInfo.fg,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 任务
          _Group(
            title: '任务',
            child: Row(
              children: [
                Icon(s.taskType.icon,
                    size: 18, color: const Color(0xFFE85D9A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.taskTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3A2A35),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 提交内容
          _Group(
            title: '提交内容',
            child: SubmissionContent(submission: s),
          ),

          const SizedBox(height: 12),

          // 时间
          _Group(
            title: '时间',
            child: Column(
              children: [
                _Item('提交时间', s.createdAt == null ? '—' : _fmt(s.createdAt!)),
                if (s.reviewedAt != null) ...[
                  _divider(),
                  _Item('审核时间', _fmt(s.reviewedAt!)),
                ],
              ],
            ),
          ),

          if (s.isRejected &&
              s.rejectReason != null &&
              s.rejectReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Group(
              title: '驳回原因',
              child: Text(
                s.rejectReason!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF8D2E5E),
                ),
              ),
            ),
          ],

          if (s.isPending && widget.onReview != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => _handleReview(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8D7C85),
                      side: const BorderSide(color: Color(0xFFEFE2EA)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('不通过'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : () => _handleReview(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE85D9A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('通过并加积分'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: const Color(0xFFEFE2EA),
      );

  _StatusInfo _statusInfo(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.pending:
        return _StatusInfo('待审核', const Color(0xFFFFF3E0),
            const Color(0xFFE58A00));
      case SubmissionStatus.approved:
        return _StatusInfo('已通过', const Color(0xFFE8F5E9), Colors.green);
      case SubmissionStatus.rejected:
        return _StatusInfo('已驳回', const Color(0xFFFFEBEE), Colors.redAccent);
    }
  }

  String _fmt(DateTime time) {
    final local = time.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusInfo {
  const _StatusInfo(this.label, this.bg, this.fg);
  final String label;
  final Color bg;
  final Color fg;
}

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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF8D7C85))),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF3A2A35)),
            ),
          ),
        ],
      ),
    );
  }
}