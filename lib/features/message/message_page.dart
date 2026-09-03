// 私聊消息页（与绑定对象的一对一聊天）
// 入口：底部导航「消息」
// 依赖：profiles.partner_id 双向绑定；未绑定对象时引导去「我的」绑定
// 特性：输入框发送、Realtime 实时收消息、打开即标记已读、下拉刷新

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../core/supabase_client.dart';
import '../../models/message.dart';
import '../../services/auth_service.dart';
import '../../services/message_service.dart';
import '../../utils/snackbar_helper.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({
    super.key,
    required this.userId,
    this.onMessagesRead,
  });

  final String userId;
  final VoidCallback? onMessagesRead;

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final _service = MessageService();
  final _authService = AuthService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  String? _partnerId;
  String _partnerNickname = '对象';
  bool _hasPartner = false;
  bool _loading = true;
  bool _sending = false;
  bool _uploading = false;

  String? _myAvatarUrl;
  String? _partnerAvatarUrl;

  List<Message> _messages = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadPartner();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPartner() async {
    setState(() => _loading = true);
    try {
      await _authService.initCurrentUser();
      final profile = await _authService.fetchMyProfile();
      final partnerId = profile?.partnerId;
      final hasPartner = partnerId != null && partnerId.isNotEmpty;
      if (!mounted) return;
      setState(() {
        _partnerId = partnerId;
        _hasPartner = hasPartner;
        _partnerNickname = profile?.partnerNickname ?? '对象';
        _myAvatarUrl = profile?.avatarUrl;
        _loading = false;
      });
      if (hasPartner && _partnerId != null) {
        final partner = await _authService.fetchProfileById(_partnerId!);
        if (partner != null && mounted) {
          setState(() {
            _partnerAvatarUrl = partner.avatarUrl;
            _partnerNickname = partner.nickname;
          });
        }
        await _loadMessages();
        _subscribe();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      SnackBarHelper.error(context, '加载失败');
    }
  }

  Future<void> _loadMessages() async {
    if (_partnerId == null) return;
    try {
      final msgs =
          await _service.fetchConversation(widget.userId, _partnerId!);
      if (!mounted) return;
      setState(() => _messages = msgs);
      await _markReadAndNotify();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.error(context, '加载失败');
    }
  }

  Future<void> _markReadAndNotify() async {
    if (_partnerId == null) return;
    try {
      await _service.markRead(myId: widget.userId, partnerId: _partnerId!);
      widget.onMessagesRead?.call();
    } catch (_) {}
  }

  void _subscribe() {
    _channel?.unsubscribe();
    _channel = AppSupabase.client
        .channel('messages:${widget.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: widget.userId,
          ),
          callback: (payload) {
            final msg = Message.fromJson(payload.newRecord);
            if (!mounted) return;
            setState(() => _messages.add(msg));
            _markReadAndNotify();
            _scrollToBottom();
          },
        )
        .subscribe();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty || _partnerId == null || _sending) return;
    setState(() => _sending = true);
    final optimistic = Message(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      senderId: widget.userId,
      receiverId: _partnerId!,
      content: text.trim(),
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages.add(optimistic);
      _controller.clear();
    });
    _scrollToBottom();
    try {
      await _service.sendMessage(
        senderId: widget.userId,
        receiverId: _partnerId!,
        content: text,
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.error(context, '发送失败，请重试');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final title = _hasPartner ? _partnerNickname : '消息';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_hasPartner
              ? _buildNoPartner()
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadMessages,
                        child: _messages.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 160),
                                  Center(
                                    child: Text(
                                      '还没有消息，发一句试试吧～',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(12),
                                itemCount: _messages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (_, index) =>
                                    _buildRow(_messages[index]),
                              ),
                      ),
                    ),
                    _buildInputBar(),
                  ],
                ),
    );
  }

  Widget _buildNoPartner() {
    return RefreshIndicator(
      onRefresh: _loadPartner,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(32, 140, 32, 24),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  size: 48, color: Color(0xFFFFB3D1)),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              '绑定对象后，你们就能在这里互发消息啦\n去「我的」页绑定 TA 吧',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: _uploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline,
                      color: Color(0xFFE85D9A), size: 28),
              onPressed: _uploading ? null : _pickAndSendMedia,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: '说点什么…',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFFF4F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: const Color(0xFFE85D9A),
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: _sending ? null : _send,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(Message m) {
    final mine = m.senderId == widget.userId;
    final avatarUrl = mine ? _myAvatarUrl : _partnerAvatarUrl;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine) _avatar(avatarUrl),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildBubbleContent(m),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(
                    _formatTime(m.createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (mine) _avatar(avatarUrl),
        ],
      ),
    );
  }

  Widget _avatar(String? url) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFFFF0F7),
      backgroundImage: url != null ? NetworkImage(url) : null,
      child: url == null
          ? const Icon(Icons.person, size: 18, color: Color(0xFFE85D9A))
          : null,
    );
  }

  Widget _buildBubbleContent(Message m) {
    if (m.isMedia) {
      final radius = BorderRadius.circular(16);
      if (m.mediaKind == 'video') {
        return ClipRRect(
          borderRadius: radius,
          child: _VideoBubble(url: m.mediaUrl!),
        );
      }
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          m.mediaUrl!,
          width: 180,
          height: 180,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
                  width: 180,
                  height: 180,
                  color: Colors.black12,
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
          errorBuilder: (_, __, ___) => Container(
            width: 180,
            height: 180,
            color: Colors.black12,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    }
    final mine = m.senderId == widget.userId;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
      decoration: BoxDecoration(
        color: mine ? const Color(0xFFE85D9A) : const Color(0xFFF1F1F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        m.content,
        style: TextStyle(
          color: mine ? Colors.white : Colors.black87,
          fontSize: 15,
        ),
      ),
    );
  }

  Future<void> _pickAndSendMedia() async {
    if (_partnerId == null || _uploading) return;
    try {
      final picker = ImagePicker();
      final file = await picker.pickMedia();
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final ext = file.path
          .split('.')
          .where((s) => s.isNotEmpty)
          .last
          .toLowerCase();
      final kind = _kindFromExt(ext);
      setState(() => _uploading = true);
      final url = await _service.uploadMedia(
        senderId: widget.userId,
        bytes: bytes,
        ext: ext,
      );
      await _service.sendMessage(
        senderId: widget.userId,
        receiverId: _partnerId!,
        msgType: 'media',
        mediaUrl: url,
        mediaKind: kind,
      );
      await _loadMessages();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.error(context, '发送失败，请重试');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _kindFromExt(String ext) {
    const videoExts = {'mp4', 'mov', 'webm', 'avi', 'mkv', 'm4v'};
    return videoExts.contains(ext) ? 'video' : 'image';
  }
}

class _VideoBubble extends StatefulWidget {
  const _VideoBubble({required this.url});

  final String url;

  @override
  State<_VideoBubble> createState() => _VideoBubbleState();
}

class _VideoBubbleState extends State<_VideoBubble> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      });
    _controller.addListener(() {
      if (mounted) setState(() => _playing = _controller.value.isPlaying);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(
        width: 180,
        height: 180,
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return GestureDetector(
      onTap: () {
        if (_controller.value.isPlaying) {
          _controller.pause();
        } else {
          _controller.play();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          if (!_playing)
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.play_arrow, color: Colors.white, size: 30),
            ),
        ],
      ),
    );
  }
}
