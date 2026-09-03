/// 任务提交弹层
///
/// 功能：根据任务类型展示不同的提交方式
/// - 文字描述：多行文本输入
/// - 图片/视频：从相册选择图片或视频，支持预览与更换
/// - 语音：直接录音，可试听与重录
///
/// 返回 [TaskSubmitResult]，由调用方完成最终入库

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../models/activity_task.dart';
import '../../services/activity_task_service.dart';
import '../../utils/snackbar_helper.dart';

/// 提交结果（媒体文件已在弹层内上传，这里只回传地址）
class TaskSubmitResult {
  TaskSubmitResult({this.content, this.mediaUrl});

  final String? content;
  final String? mediaUrl;
}

class TaskSubmitSheet extends StatefulWidget {
  const TaskSubmitSheet({
    super.key,
    required this.task,
    required this.userId,
  });

  final ActivityTask task;
  final String userId;

  @override
  State<TaskSubmitSheet> createState() => _TaskSubmitSheetState();
}

class _TaskSubmitSheetState extends State<TaskSubmitSheet> {
  final _service = ActivityTaskService();
  final _picker = ImagePicker();
  final _textController = TextEditingController();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  Uint8List? _mediaBytes;
  MediaKind? _mediaKind;
  String? _mediaName;

  bool _uploading = false;
  bool _recording = false;
  bool _playing = false;
  int _seconds = 0;
  Timer? _timer;
  String? _audioPath;

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1440,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _mediaBytes = bytes;
      _mediaKind = MediaKind.image;
      _mediaName = file.name;
    });
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _mediaBytes = bytes;
      _mediaKind = MediaKind.video;
      _mediaName = file.name;
    });
  }

  Future<void> _startRecord() async {
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      SnackBarHelper.error(context, '需要麦克风权限才能录音');
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/task_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );

    if (!mounted) return;
    setState(() {
      _recording = true;
      _seconds = 0;
      _mediaBytes = null;
      _mediaKind = null;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
    });
  }

  Future<void> _stopRecord() async {
    final path = await _recorder.stop();
    _timer?.cancel();
    if (!mounted) return;

    if (path == null) {
      setState(() => _recording = false);
      return;
    }

    final bytes = await File(path).readAsBytes();
    if (!mounted) return;
    setState(() {
      _recording = false;
      _audioPath = path;
      _mediaBytes = bytes;
      _mediaKind = MediaKind.audio;
      _mediaName = '语音 $_seconds 秒';
    });
  }

  Future<void> _togglePlay() async {
    if (_audioPath == null) return;
    if (_playing) {
      await _player.stop();
      if (!mounted) return;
      setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    await _player.play(DeviceFileSource(_audioPath!));
    await _player.onPlayerComplete.first;
    if (!mounted) return;
    setState(() => _playing = false);
  }

  Future<void> _resetMedia() async {
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _mediaBytes = null;
      _mediaKind = null;
      _mediaName = null;
      _audioPath = null;
      _playing = false;
      _seconds = 0;
    });
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();

    if (widget.task.type == TaskType.text && text.isEmpty) {
      SnackBarHelper.warning(context, '请填写任务内容');
      return;
    }
    if (widget.task.type != TaskType.text && _mediaBytes == null) {
      SnackBarHelper.warning(
        context,
        widget.task.type == TaskType.audio ? '请先录制语音' : '请先选择图片或视频',
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      String? mediaUrl;
      if (_mediaBytes != null && _mediaKind != null) {
        mediaUrl = await _service.uploadMedia(
          bytes: _mediaBytes!,
          userId: widget.userId,
          kind: _mediaKind!,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(
        TaskSubmitResult(
          content: text.isEmpty ? null : text,
          mediaUrl: mediaUrl,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.error(context, '上传失败，请重试');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.task.type.icon, color: const Color(0xFFE85D9A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.task.title,
                    style: const TextStyle(
                      fontSize: 17,
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
                    '+${widget.task.points} 积分',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF9900),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.task.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                widget.task.description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 14),
            _buildSubmitArea(),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _uploading ? null : _submit,
                child: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('提交任务'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitArea() {
    switch (widget.task.type) {
      case TaskType.text:
        return TextField(
          controller: _textController,
          maxLines: 5,
          minLines: 3,
          decoration: const InputDecoration(
            hintText: '写下你的完成情况…',
          ),
        );
      case TaskType.media:
        return _buildMediaArea();
      case TaskType.audio:
        return _buildAudioArea();
    }
  }

  Widget _buildMediaArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: const Text('选择图片'),
            ),
            OutlinedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.videocam_outlined),
              label: const Text('选择视频'),
            ),
          ],
        ),
        if (_mediaKind == MediaKind.image && _mediaBytes != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              _mediaBytes!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
        if (_mediaBytes != null) ...[
          const SizedBox(height: 8),
          _buildMediaInfoRow(),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: _textController,
          maxLines: 2,
          minLines: 1,
          decoration: const InputDecoration(
            hintText: '补充说明（选填）',
          ),
        ),
      ],
    );
  }

  Widget _buildMediaInfoRow() {
    final sizeKb = (_mediaBytes!.lengthInBytes / 1024).round();
    return Row(
      children: [
        Icon(
          _mediaKind == MediaKind.video
              ? Icons.video_file_outlined
              : (_mediaKind == MediaKind.audio
                  ? Icons.audiotrack_outlined
                  : Icons.image_outlined),
          size: 18,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${_mediaName ?? '已选择文件'} · ${sizeKb}KB',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
        TextButton(
          onPressed: _resetMedia,
          child: const Text('重新选择'),
        ),
      ],
    );
  }

  Widget _buildAudioArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE1EE)),
          ),
          child: Column(
            children: [
              Text(
                _recording ? '录音中 00:${_seconds.toString().padLeft(2, '0')}' : (_audioPath == null ? '点击麦克风开始录音' : '录音完成 · $_seconds 秒'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'recordBtn',
                    backgroundColor:
                        _recording ? Colors.redAccent : const Color(0xFFE85D9A),
                    onPressed: _recording ? _stopRecord : _startRecord,
                    child: Icon(_recording ? Icons.stop : Icons.mic),
                  ),
                  if (_audioPath != null && !_recording) ...[
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _togglePlay,
                      icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
                      label: Text(_playing ? '停止' : '试听'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _resetMedia,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重录'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _textController,
          maxLines: 2,
          minLines: 1,
          decoration: const InputDecoration(
            hintText: '补充说明（选填）',
          ),
        ),
      ],
    );
  }
}
