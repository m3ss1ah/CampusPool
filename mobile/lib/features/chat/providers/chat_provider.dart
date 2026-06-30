import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/chat_api.dart';
import '../domain/conversation_model.dart';
import '../domain/message_model.dart';
import '../../../core/network/socket_client.dart';
import '../../../core/cache/hive_setup.dart';

part 'chat_provider.g.dart';

@riverpod
class ConversationsNotifier extends _$ConversationsNotifier {
  final _api = ChatApi();

  @override
  FutureOr<List<ConversationModel>> build() async {
    _loadFromCache();
    return _fetchConversations();
  }

  void _loadFromCache() {
    final box = Hive.box<String>(HiveSetup.conversationsBoxName);
    final cached = box.get('conversations');
    if (cached != null) {
      final List decoded = json.decode(cached);
      state = AsyncData(decoded.map((e) => ConversationModel.fromJson(e)).toList());
    }
  }

  Future<List<ConversationModel>> _fetchConversations() async {
    final convs = await _api.getConversations();
    final box = Hive.box<String>(HiveSetup.conversationsBoxName);
    box.put('conversations', json.encode(convs.map((e) => e.toJson()).toList()));
    return convs;
  }

  Future<void> refresh() async {
    // Note: Don't set state to AsyncLoading if we have cached data, so UI doesn't flash
    state = await AsyncValue.guard(() => _fetchConversations());
  }

  Future<ConversationModel> createConversation(String targetUserId, String commuteId) async {
    final conv = await _api.createConversation(targetUserId, commuteId);
    await refresh();
    return conv;
  }
}

@riverpod
class MessagesNotifier extends _$MessagesNotifier {
  final _api = ChatApi();
  String? _conversationId;

  @override
  FutureOr<List<MessageModel>> build(String conversationId) async {
    _conversationId = conversationId;
    _loadFromCache();
    _setupSocket();
    return _fetchMessages();
  }

  void _loadFromCache() {
    final box = Hive.box<String>(HiveSetup.messagesBoxName);
    final cached = box.get('messages_$_conversationId');
    if (cached != null) {
      final List decoded = json.decode(cached);
      state = AsyncData(decoded.map((e) => MessageModel.fromJson(e)).toList());
    }
  }

  void _setupSocket() {
    final socketClient = ref.read(socketClientProvider);
    socketClient.emit('join_conversation', {'conversation_id': _conversationId});

    socketClient.on('new_message', (data) {
      if (data['conversation_id'] == _conversationId) {
        final message = MessageModel.fromJson(data);
        final currentMessages = state.value ?? [];
        final newMsgs = [message, ...currentMessages];
        state = AsyncData(newMsgs);
        _cacheMessages(newMsgs);
      }
    });

    socketClient.on('message_deleted', (data) {
      if (data['conversation_id'] == _conversationId) {
        final currentMessages = state.value ?? [];
        final updated = currentMessages.map((m) {
          if (m.id == data['message_id']) {
            return m.copyWith(content: 'Message deleted', deletedAt: DateTime.parse(data['deleted_at']));
          }
          return m;
        }).toList();
        state = AsyncData(updated);
        _cacheMessages(updated);
      }
    });

    ref.onDispose(() {
      socketClient.emit('leave_conversation', {'conversation_id': _conversationId});
      socketClient.off('new_message');
      socketClient.off('message_deleted');
    });
  }

  void _cacheMessages(List<MessageModel> messages) {
    final box = Hive.box<String>(HiveSetup.messagesBoxName);
    box.put('messages_$_conversationId', json.encode(messages.map((e) => e.toJson()).toList()));
  }

  Future<List<MessageModel>> _fetchMessages() async {
    final result = await _api.getMessages(_conversationId!);
    final messages = result['messages'] as List<MessageModel>;
    _cacheMessages(messages);
    return messages;
  }

  Future<void> sendMessage(String content) async {
    try {
      await _api.sendMessage(_conversationId!, content);
      // We don't manually add to state here, let the socket 'new_message' event handle it
      // to ensure consistency across devices and avoid duplicates.
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    await _api.deleteMessage(messageId);
    // Socket event 'message_deleted' will handle state update
  }
}
