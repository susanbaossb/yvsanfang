/// 媒体预览页面
///
/// 功能：审核任务提交时查看大图或播放视频

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../models/activity_task.dart';

class MediaPreviewPage extends StatefulWidget {
  const MediaPreviewPage({
    super.key,
    required this.url,
    required this.kind,
  });

  final String url;
  final MediaKind kind;

  @override
  State<MediaPreviewPage> createState() => _MediaPreviewPageState();
}

class _MediaPreviewPageState extends State<MediaPreviewPage> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.kind == MediaKind.video) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      await controller.play();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '视频加载失败');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_title),
      ),
      body: Center(child: _buildBody()),
    );
  }

  String get _title {
    switch (widget.kind) {
      case MediaKind.image:
        return '查看图片';
      case MediaKind.video:
        return '播放视频';
      case MediaKind.audio:
        return '播放语音';
    }
  }

  Widget _buildBody() {
    if (widget.kind == MediaKind.image) {
      return InteractiveViewer(
        child: Image.network(
          widget.url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Text('图片加载失败', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: Colors.white));
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return const CircularProgressIndicator();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        const SizedBox(height: 16),
        IconButton(
          iconSize: 44,
          color: Colors.white,
          onPressed: () {
            setState(() {
              _controller!.value.isPlaying
                  ? _controller!.pause()
                  : _controller!.play();
            });
          },
          icon: Icon(
            _controller!.value.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
          ),
        ),
      ],
    );
  }
}
