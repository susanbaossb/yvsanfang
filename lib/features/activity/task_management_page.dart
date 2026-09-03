/// 任务管理页面（管理员功能）
///
/// 功能：新增 / 编辑 / 删除 / 启用停用活动任务
/// - 标题、描述、完成后获得的积分、任务类型（文字描述 / 图片视频 / 语音）
///
/// 说明：用户提交任务后的审核在「我的 → 消息通知」中由绑定对象完成。
///
/// 入口：我的 → 活动任务（与菜单管理、消息通知并列的快捷入口）

import 'package:flutter/material.dart';

import '../../models/activity_task.dart';
import '../../services/activity_task_service.dart';
import '../../utils/snackbar_helper.dart';

/// 任务表单提交的数据
class _TaskDraft {
  _TaskDraft({
    required this.title,
    required this.description,
    required this.points,
    required this.type,
    required this.enabled,
  });

  final String title;
  final String description;
  final int points;
  final TaskType type;
  final bool enabled;
}

class TaskManagementPage extends StatefulWidget {
  const TaskManagementPage({super.key});

  @override
  State<TaskManagementPage> createState() => _TaskManagementPageState();
}

class _TaskManagementPageState extends State<TaskManagementPage> {
  final _service = ActivityTaskService();

  List<ActivityTask> _tasks = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final tasks = await _service.fetchTasks(onlyEnabled: false);
      if (!mounted) return;
      setState(() => _tasks = tasks);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.error(context, '加载失败');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showTaskDialog({ActivityTask? task}) async {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController = TextEditingController(text: task?.description ?? '');
    final pointsController =
        TextEditingController(text: task == null ? '5' : '${task.points}');
    TaskType type = task?.type ?? TaskType.text;
    bool enabled = task?.enabled ?? true;

    final draft = await showDialog<_TaskDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(task == null ? '新增任务' : '编辑任务'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '任务标题',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    minLines: 2,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '任务描述',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pointsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '完成后获得积分',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('任务类型',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedButton<TaskType>(
                    segments: TaskType.values
                        .map(
                          (item) => ButtonSegment<TaskType>(
                            value: item,
                            icon: Icon(item.icon),
                            label: Text(item.label),
                          ),
                        )
                        .toList(),
                    selected: {type},
                    onSelectionChanged: (selected) =>
                        setDialogState(() => type = selected.first),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('启用任务'),
                    value: enabled,
                    onChanged: (value) =>
                        setDialogState(() => enabled = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                final points = int.tryParse(pointsController.text.trim());
                if (title.isEmpty) {
                  SnackBarHelper.warning(context, '请填写任务标题');
                  return;
                }
                if (points == null || points < 0) {
                  SnackBarHelper.warning(context, '积分需为不小于 0 的整数');
                  return;
                }
                Navigator.of(dialogContext).pop(
                  _TaskDraft(
                    title: title,
                    description: descController.text.trim(),
                    points: points,
                    type: type,
                    enabled: enabled,
                  ),
                );
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (draft == null) return;

    setState(() => _saving = true);
    try {
      if (task == null) {
        await _service.createTask(
          title: draft.title,
          description: draft.description,
          points: draft.points,
          type: draft.type,
          enabled: draft.enabled,
          sortOrder: _tasks.length,
        );
      } else {
        await _service.updateTask(
          taskId: task.id,
          title: draft.title,
          description: draft.description,
          points: draft.points,
          type: draft.type,
          enabled: draft.enabled,
          sortOrder: task.sortOrder,
        );
      }
      if (!mounted) return;
      SnackBarHelper.success(context, task == null ? '任务已创建' : '任务已更新');
      await _load();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.error(context, '保存失败');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleEnabled(ActivityTask task, bool value) async {
    try {
      await _service.setTaskEnabled(taskId: task.id, enabled: value);
      if (!mounted) return;
      setState(() {
        _tasks = _tasks
            .map((item) => item.id == task.id
                ? ActivityTask(
                    id: item.id,
                    title: item.title,
                    description: item.description,
                    points: item.points,
                    type: item.type,
                    enabled: value,
                    sortOrder: item.sortOrder,
                    createdAt: item.createdAt,
                  )
                : item)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.error(context, '操作失败');
    }
  }

  Future<void> _deleteTask(ActivityTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定删除任务「${task.title}」吗？已提交的记录会保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteTask(taskId: task.id);
      if (!mounted) return;
      SnackBarHelper.success(context, '任务已删除');
      await _load();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.error(context, '删除失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务管理'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_tasks.isEmpty
              ? RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 120, 12, 12),
                    children: const [
                      Center(child: Text('还没有任务，点击右下角新增')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: _tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) => _buildTaskCard(_tasks[index]),
                  ),
                )),
    );
  }

  Widget _buildTaskCard(ActivityTask task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(task.type.icon, size: 20, color: const Color(0xFFE85D9A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+${task.points}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF9900),
                    ),
                  ),
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _TaskTypePill(type: task.type),
                const Spacer(),
                const Text('启用'),
                Switch(
                  value: task.enabled,
                  onChanged: _saving ? null : (value) => _toggleEnabled(task, value),
                ),
                IconButton(
                  onPressed: () => _showTaskDialog(task: task),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: '编辑',
                ),
                IconButton(
                  onPressed: () => _deleteTask(task),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '删除',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 任务类型胶囊：自绘避免 M3 主题下 Chip 文字色被吞
class _TaskTypePill extends StatelessWidget {
  const _TaskTypePill({required this.type});

  final TaskType type;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (type) {
      TaskType.text => (
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0),
          Icons.text_snippet_outlined,
        ),
      TaskType.media => (
          const Color(0xFFFFF3E0),
          const Color(0xFFE58A00),
          Icons.image_outlined,
        ),
      TaskType.audio => (
          const Color(0xFFF3E5F5),
          const Color(0xFF6A1B9A),
          Icons.mic_none_rounded,
        ),
    };

    return Container(
      height: 28,
      constraints: const BoxConstraints(minWidth: 60),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
