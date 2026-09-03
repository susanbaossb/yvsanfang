// 消息模型
// 字段说明：
// - id: 消息唯一标识（UUID）
// - senderId: 发送方用户 ID
// - receiverId: 接收方用户 ID
// - content: 消息文本
// - createdAt: 发送时间
// - readAt: 接收方已读时间（null 表示未读）

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.readAt,
    this.msgType = 'text',
    this.mediaUrl,
    this.mediaKind,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;

  /// 'text' | 'media'
  final String msgType;
  /// 媒体文件公开地址（图片/视频/gif）
  final String? mediaUrl;
  /// 'image' | 'video'
  final String? mediaKind;

  bool get isRead => readAt != null;
  bool get isMedia => msgType == 'media' && mediaUrl != null;

  factory Message.fromJson(Map<String, dynamic> json) {
    final rawCreated = json['created_at'];
    final rawRead = json['read_at'];
    return Message(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String? ?? '',
      createdAt: rawCreated is String
          ? DateTime.parse(rawCreated)
          : DateTime.fromMillisecondsSinceEpoch(rawCreated as int),
      readAt: rawRead == null
          ? null
          : (rawRead is String
              ? DateTime.parse(rawRead)
              : DateTime.fromMillisecondsSinceEpoch(rawRead as int)),
      msgType: json['msg_type'] as String? ?? 'text',
      mediaUrl: json['media_url'] as String?,
      mediaKind: json['media_kind'] as String?,
    );
  }
}
