/// 任务提交审核卡片（可复用组件）
///
/// 功能：展示一条任务提交的完整信息与操作按钮
/// - 提交人昵称、任务标题、奖励积分
/// - 提交内容：文字直接展示、图片显示缩略图、视频可播放、语音可试听
/// - 通过 / 驳回按钮（由外部传入回调，通过后由服务层发放积分）
///
/// 使用位置：消息与提醒页（对象审核）

import 'package:flutter/material.dart';

import '../../models/activity_task.dart';
import 'submission_content.dart';

typedef ReviewCallback = Future<void> Function(
  TaskSubmission submission,
  bool approved,
);

class TaskReviewCard extends StatelessWidget {
  const TaskReviewCard({
    super.key,
    required this.submission,
    required this.onReview,
    this.onTap,
    this.saving = false,
  });

  final TaskSubmission submission;
  final ReviewCallback onReview;

  /// 点击卡片打开详情页（内容区可点，操作按钮区不触发）
  final VoidCallback? onTap;

  /// 审核中：禁用按钮避免重复提交
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFFFF0F7),
                        child: Text(
                          submission.nickname.isNotEmpty
                              ? submission.nickname.substring(0, 1)
                              : '?',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE85D9A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          submission.nickname,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3A2A35),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '+${submission.taskPoints}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE58A00),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(submission.taskType.icon,
                          size: 18, color: const Color(0xFFE85D9A)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          submission.taskTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3A2A35),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (submission.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(submission.createdAt!),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SubmissionContent(submission: submission),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        saving ? null : () => onReview(submission, false),
                    child: const Text('不通过'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed:
                        saving ? null : () => onReview(submission, true),
                    child: const Text('通过并加积分'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
}

