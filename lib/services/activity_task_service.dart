/// 活动任务服务
///
/// 功能：
/// 1. fetchTasks: 获取任务列表（默认只取启用中的）
/// 2. createTask / updateTask / setTaskEnabled / deleteTask: 任务配置
/// 3. fetchMySubmissions: 获取我的提交记录
/// 4. fetchSubmissions: 获取提交记录（审核用，可按状态过滤）
/// 5. uploadMedia: 上传图片/视频/语音到 Storage
/// 6. submitTask: 提交任务（同一任务在待审核/已通过状态下不可重复提交）
/// 7. reviewSubmission: 审核提交，通过后发放积分

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_client.dart';
import '../models/activity_task.dart';
import 'points_service.dart';

class ActivityTaskService {
  static const String _tasksTable = 'activity_tasks';
  static const String _submissionsTable = 'activity_task_submissions';
  static const String _bucket = 'activity-media';

  final _pointsService = PointsService();

  /// 获取任务列表
  Future<List<ActivityTask>> fetchTasks({bool onlyEnabled = true}) async {
    var query = AppSupabase.client
        .from(_tasksTable)
        .select()
        .eq('deleted', false);

    if (onlyEnabled) {
      query = query.eq('enabled', true);
    }

    final rows = await query.order('sort_order').order('created_at');
    return rows
        .map<ActivityTask>((row) => ActivityTask.fromJson(row))
        .toList();
  }

  Future<void> createTask({
    required String title,
    required String description,
    required int points,
    required TaskType type,
    required bool enabled,
    int sortOrder = 0,
  }) async {
    await AppSupabase.client.from(_tasksTable).insert({
      'title': title,
      'description': description,
      'points': points,
      'type': type.value,
      'enabled': enabled,
      'sort_order': sortOrder,
    });
  }

  Future<void> updateTask({
    required String taskId,
    required String title,
    required String description,
    required int points,
    required TaskType type,
    required bool enabled,
    int sortOrder = 0,
  }) async {
    await AppSupabase.client.from(_tasksTable).update({
      'title': title,
      'description': description,
      'points': points,
      'type': type.value,
      'enabled': enabled,
      'sort_order': sortOrder,
    }).eq('id', taskId);
  }

  /// 启用/停用任务
  Future<void> setTaskEnabled({
    required String taskId,
    required bool enabled,
  }) async {
    await AppSupabase.client
        .from(_tasksTable)
        .update({'enabled': enabled}).eq('id', taskId);
  }

  /// 删除任务（软删除）
  Future<void> deleteTask({required String taskId}) async {
    await AppSupabase.client
        .from(_tasksTable)
        .update({'deleted': true}).eq('id', taskId);
  }

  /// 获取我的提交记录
  Future<List<TaskSubmission>> fetchMySubmissions(String userId) async {
    final rows = await AppSupabase.client
        .from(_submissionsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows
        .map<TaskSubmission>((row) => TaskSubmission.fromJson(row))
        .toList();
  }

  /// 待我审核：绑定对象提交的、状态为待审核的记录
  Future<List<TaskSubmission>> fetchPartnerPending(String partnerId) async {
    final rows = await AppSupabase.client
        .from(_submissionsTable)
        .select()
        .eq('user_id', partnerId)
        .eq('status', SubmissionStatus.pending.value)
        .order('created_at', ascending: false);
    return rows
        .map<TaskSubmission>((row) => TaskSubmission.fromJson(row))
        .toList();
  }

  /// 我的提交回执：已通过 / 已驳回的记录
  Future<List<TaskSubmission>> fetchMyResults(String userId) async {
    final rows = await AppSupabase.client
        .from(_submissionsTable)
        .select()
        .eq('user_id', userId)
        .inFilter('status', [
          SubmissionStatus.approved.value,
          SubmissionStatus.rejected.value,
        ])
        .order('created_at', ascending: false);
    return rows
        .map<TaskSubmission>((row) => TaskSubmission.fromJson(row))
        .toList();
  }

  /// 获取提交记录（审核用）
  Future<List<TaskSubmission>> fetchSubmissions({
    SubmissionStatus? status,
  }) async {
    var query = AppSupabase.client.from(_submissionsTable).select();

    if (status != null) {
      query = query.eq('status', status.value);
    }

    final rows = await query.order('created_at', ascending: false);
    return rows
        .map<TaskSubmission>((row) => TaskSubmission.fromJson(row))
        .toList();
  }

  /// 上传任务媒体文件（图片/视频/语音）
  Future<String> uploadMedia({
    required Uint8List bytes,
    required String userId,
    required MediaKind kind,
  }) async {
    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}.${kind.ext}';
    await AppSupabase.client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: kind.contentType,
          ),
        );
    return AppSupabase.client.storage.from(_bucket).getPublicUrl(path);
  }

  /// 提交任务
  Future<void> submitTask({
    required ActivityTask task,
    required String userId,
    required String nickname,
    String? content,
    String? mediaUrl,
  }) async {
    final duplicated = await AppSupabase.client
        .from(_submissionsTable)
        .select('id')
        .eq('task_id', task.id)
        .eq('user_id', userId)
        .inFilter('status', ['pending', 'approved'])
        .maybeSingle();

    if (duplicated != null) {
      throw Exception('该任务已提交，请勿重复提交');
    }

    await AppSupabase.client.from(_submissionsTable).insert({
      'task_id': task.id,
      'user_id': userId,
      'nickname': nickname,
      'task_title': task.title,
      'task_points': task.points,
      'task_type': task.type.value,
      'content': content,
      'media_url': mediaUrl,
      'status': SubmissionStatus.pending.value,
    });
  }

  /// 审核提交：通过后按任务积分给用户加积分
  Future<int> reviewSubmission({
    required TaskSubmission submission,
    required bool approved,
    String? rejectReason,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final rows = await AppSupabase.client
        .from(_submissionsTable)
        .update({
          'status': approved
              ? SubmissionStatus.approved.value
              : SubmissionStatus.rejected.value,
          'reject_reason': approved ? null : rejectReason,
          'reviewed_at': now,
        })
        .eq('id', submission.id)
        .eq('status', SubmissionStatus.pending.value)
        .select();

    if (rows.isEmpty) {
      throw Exception('该提交已被处理，请刷新后重试');
    }

    if (!approved) return 0;

    return _pointsService.changePoints(
      userId: submission.userId,
      delta: submission.taskPoints,
    );
  }
}
