import 'package:dio/dio.dart';
import '../domain/conversation_model.dart';
import '../domain/message_model.dart';
import '../../../core/network/dio_client.dart';

class ChatApi {
  final Dio _dio = DioClient().dio;

  Future<List<ConversationModel>> getConversations() async {
    final response = await _dio.get('chat/conversations');
    final data = response.data['data']['conversations'] as List;
    return data.map((e) => ConversationModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getMessages(String conversationId, {String? cursor}) async {
    final response = await _dio.get('chat/conversations/$conversationId/messages', queryParameters: {
      if (cursor != null) 'cursor': cursor,
    });
    
    final data = response.data['data'] as List;
    final messages = data.map((e) => MessageModel.fromJson(e)).toList();
    final cursorData = response.data['cursor'];
    
    return {
      'messages': messages,
      'next_cursor': cursorData['next_cursor'],
      'has_more': cursorData['has_more'] ?? false,
    };
  }

  Future<ConversationModel> createConversation(String targetUserId, String commuteId) async {
    final response = await _dio.post('chat/conversations', data: {
      'target_user_id': targetUserId,
      'commute_id': commuteId,
    });
    return ConversationModel.fromJson(response.data['data']['conversation']);
  }

  Future<MessageModel> sendMessage(String conversationId, String content) async {
    final response = await _dio.post('chat/conversations/$conversationId/messages', data: {
      'content': content,
    });
    return MessageModel.fromJson(response.data['data']);
  }

  Future<void> deleteMessage(String messageId) async {
    await _dio.delete('chat/messages/$messageId');
  }
}
