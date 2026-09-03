/// 任务提交内容展示（文字 / 图片 / 视频 / 语音）
///
/// 复用于「审核卡片」与「任务详情页」，保证媒体预览 / 语音播放逻辑一致。

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../models/activity_task.dart';
import '../../utils/snackbar_helper.dart';
import 'media_preview_page.dart';

class SubmissionContent extends StatelessWidget {
  const SubmissionContent({super.key, required this.submission});

  final TaskSubmission submission;

  @override
  Widget build(BuildContext context) {
    final url = submission.mediaUrl;
    final content = submission.content;

    Widget? media;
    if (submission.taskType == TaskType.audio) {
      media = AudioPlayButton(url: url ?? '');
    } else if (submission.taskType == TaskType.media &&
        url != null &&
        url.isNotEmpty) {
      media = _buildImageOrVideoPreview(context, url);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content != null && content.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF5C4A56),
              ),
            ),
          ),
        if (media != null) ...[
          if (content != null && content.isNotEmpty)
            const SizedBox(height: 8),
          media,
        ],
        if ((content == null || content.isEmpty) && media == null)
          const Text('（无提交内容）', style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildImageOrVideoPreview(BuildContext context, String url) {
    if (!_isVideoUrl(url)) {
      return GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MediaPreviewPage(url: url, kind: MediaKind.image),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(
              height: 80,
              child: Center(child: Text('图片加载失败')),
            ),
          ),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MediaPreviewPage(url: url, kind: MediaKind.video),
        ),
      ),
      child: Container(
        height: 80,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_fill, size: 34, color: Color(0xFFE85D9A)),
            SizedBox(width: 8),
            Text('点击播放视频'),
          ],
        ),
      ),
    );
  }

  bool _isVideoUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.m4v');
  }
}

/// 语音播放按钮（详情 / 审核时试听对方提交的录音）
class AudioPlayButton extends StatefulWidget {
  const AudioPlayButton({super.key, required this.url});

  final String url;

  @override
  State<AudioPlayButton> createState() => _AudioPlayButtonState();
}

class _AudioPlayButtonState extends State<AudioPlayButton> {
  final _player = AudioPlayer();
  bool _playing = false;
  bool _loading = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (widget.url.isEmpty) return;
    if (_playing) {
      await _player.stop();
      if (!mounted) return;
      setState(() => _playing = false);
      return;
    }

    setState(() => _loading = true);
    try {
      await _player.play(UrlSource(widget.url));
      if (!mounted) return;
      setState(() {
        _loading = false;
        _playing = true;
      });
      await _player.onPlayerComplete.first;
      if (!mounted) return;
      setState(() => _playing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      SnackBarHelper.error(context, '语音播放失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _loading ? null : _toggle,
      icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
      label: Text(_playing ? '停止播放' : (_loading ? '加载中…' : '播放语音')),
    );
  }
}
