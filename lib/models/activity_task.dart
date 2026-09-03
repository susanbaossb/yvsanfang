/// 活动任务模型
///
/// 功能：
/// - TaskType：任务类型（文字描述 / 图片视频 / 语音）
/// - ActivityTask：活动任务配置（标题、描述、积分、类型、是否启用）
/// - SubmissionStatus：任务提交审核状态
/// - TaskSubmission：用户提交任务的记录
/// - MediaKind：提交内容中的媒体类型（用于预览与播放）

import 'package:flutter/material.dart';

/// 任务类型
enum TaskType {
  text('text', '文字描述', Icons.text_fields_outlined),
  media('media', '图片/视频', Icons.perm_media_outlined),
  audio('audio', '语音', Icons.mic_outlined);

  const TaskType(this.value, this.label, this.icon);

  /// 写入数据库的值
  final String value;

  /// 中文展示名
  final String label;

  /// 列表/表单中的图标
  final IconData icon;

  static TaskType fromValue(String? value) {
    return TaskType.values.firstWhere(
      (item) => item.value == value,
      orElse: () => TaskType.text,
    );
  }
}

/// 媒体类型（图片 / 视频 / 语音）
enum MediaKind {
  image,
  video,
  audio;

  /// 上传文件的扩展名
  String get ext {
    switch (this) {
      case MediaKind.image:
        return 'jpg';
      case MediaKind.video:
        return 'mp4';
      case MediaKind.audio:
        return 'm4a';
    }
  }

  /// 上传文件的 MIME 类型
  String get contentType {
    switch (this) {
      case MediaKind.image:
        return 'image/jpeg';
      case MediaKind.video:
        return 'video/mp4';
      case MediaKind.audio:
        return 'audio/mp4';
    }
  }
}

/// 活动任务
class ActivityTask {
  ActivityTask({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.type,
    required this.enabled,
    required this.sortOrder,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;

  /// 完成后可获得的积分
  final int points;

  final TaskType type;

  /// 是否启用（停用后活动页不再展示）
  final bool enabled;

  final int sortOrder;
  final DateTime? createdAt;

  factory ActivityTask.fromJson(Map<String, dynamic> json) {
    return ActivityTask(
      id: json['id'].toString(),
      title: (json['title'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      points: (json['points'] as num?)?.toInt() ?? 0,
      type: TaskType.fromValue(json['type'] as String?),
      enabled: json['enabled'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  /// 用于新增/更新，不含服务端维护的字段
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'points': points,
      'type': type.value,
      'enabled': enabled,
      'sort_order': sortOrder,
    };
  }
}

/// 任务提交审核状态
enum SubmissionStatus {
  pending('pending', '待审核'),
  approved('approved', '已通过'),
  rejected('rejected', '已驳回');

  const SubmissionStatus(this.value, this.label);

  final String value;
  final String label;

  static SubmissionStatus fromValue(String? value) {
    return SubmissionStatus.values.firstWhere(
      (item) => item.value == value,
      orElse: () => SubmissionStatus.pending,
    );
  }
}

/// 任务提交记录
class TaskSubmission {
  TaskSubmission({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.nickname,
    required this.taskTitle,
    required this.taskPoints,
    required this.taskType,
    required this.status,
    this.content,
    this.mediaUrl,
    this.rejectReason,
    this.createdAt,
    this.reviewedAt,
  });

  final String id;
  final String taskId;
  final String userId;
  final String nickname;

  /// 提交时冗余的任务信息，避免审核时再做联表查询
  final String taskTitle;
  final int taskPoints;
  final TaskType taskType;

  /// 文字描述内容
  final String? content;

  /// 图片/视频/语音地址
  final String? mediaUrl;

  final SubmissionStatus status;
  final String? rejectReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  bool get isPending => status == SubmissionStatus.pending;
  bool get isApproved => status == SubmissionStatus.approved;
  bool get isRejected => status == SubmissionStatus.rejected;

  factory TaskSubmission.fromJson(Map<String, dynamic> json) {
    return TaskSubmission(
      id: json['id'].toString(),
      taskId: json['task_id'].toString(),
      userId: json['user_id'].toString(),
      nickname: (json['nickname'] as String? ?? '').trim(),
      taskTitle: (json['task_title'] as String? ?? '').trim(),
      taskPoints: (json['task_points'] as num?)?.toInt() ?? 0,
      taskType: TaskType.fromValue(json['task_type'] as String?),
      status: SubmissionStatus.fromValue(json['status'] as String?),
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String?,
      rejectReason: json['reject_reason'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      reviewedAt: json['reviewed_at'] == null
          ? null
          : DateTime.tryParse(json['reviewed_at'].toString()),
    );
  }
}
