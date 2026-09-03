// 消息服务
// 功能：
// 1. sendMessage: 发送一条消息给绑定对象
// 2. fetchConversation: 拉取两人之间的全部对话（按时间正序）
// 3. markRead: 把「对方发给我且未读」的消息标记为已读
// 4. fetchUnreadCount: 我收到的未读消息数（用于首页角标）

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/supabase_client.dart';
import '../models/message.dart';

class MessageService {
  static const String _table = 'messages';

  /// 发送消息
  ///
  /// [msgType] 为 'text' 或 'media'；媒体消息需提供 [mediaUrl] 与 [mediaKind]（'image'|'video'）
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    String? content,
    String msgType = 'text',
    String? mediaUrl,
    String? mediaKind,
  }) async {
    final data = <String, dynamic>{
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content?.trim() ?? '',
      'msg_type': msgType,
      'media_url': mediaUrl,
      'media_kind': mediaKind,
    };
    await AppSupabase.client.from(_table).insert(data);
  }

  /// 上传聊天媒体文件到 Storage，返回公开地址
  ///
  /// [ext] 为文件扩展名（不含点），如 jpg/png/gif/mp4/mov
  Future<String> uploadMedia({
    required String senderId,
    required Uint8List bytes,
    required String ext,
  }) async {
    final safe = ext.toLowerCase();
    final fileName = '${senderId}_${const Uuid().v4()}.$safe';
    final path = 'messages/$fileName';
    await AppSupabase.client.storage.from('dish-images').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: _contentType(safe)),
        );
    return AppSupabase.client.storage.from('dish-images').getPublicUrl(path);
  }

  String _contentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
      case 'm4v':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      default:
        return 'application/octet-stream';
    }
  }

  /// 拉取两人之间的全部对话（按时间正序）
  Future<List<Message>> fetchConversation(String userA, String userB) async {
    final rows = await AppSupabase.client
        .from(_table)
        .select()
        .or(
          'and(sender_id.eq.$userA,receiver_id.eq.$userB),'
          'and(sender_id.eq.$userB,receiver_id.eq.$userA)',
        )
        .order('created_at', ascending: true);
    return rows.map<Message>((r) => Message.fromJson(r)).toList();
  }

  /// 把「对方发给我、且未读」的消息标记为已读
  Future<void> markRead({
    required String myId,
    required String partnerId,
  }) async {
    await AppSupabase.client
        .from(_table)
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('sender_id', partnerId)
        .eq('receiver_id', myId)
        .isFilter('read_at', null);
  }

  /// 我收到的未读消息数
  Future<int> fetchUnreadCount(String myId) async {
    final result = await AppSupabase.client
        .from(_table)
        .select('id')
        .eq('receiver_id', myId)
        .isFilter('read_at', null);
    return result.length;
  }
}
