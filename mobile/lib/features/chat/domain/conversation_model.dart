import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation_model.freezed.dart';
part 'conversation_model.g.dart';

@freezed
class ConversationModel with _$ConversationModel {
  const factory ConversationModel({
    required String id,
    @JsonKey(name: 'commute_id') String? commuteId,
    @JsonKey(name: 'last_message') String? lastMessage,
    @JsonKey(name: 'last_message_at') DateTime? lastMessageAt,
    @JsonKey(name: 'other_user_id') required String otherUserId,
    @JsonKey(name: 'full_name') required String otherUserName,
    @JsonKey(name: 'profile_pic_url') String? otherUserPic,
    @JsonKey(name: 'source_label') String? sourceLabel,
    @JsonKey(name: 'dest_label') String? destLabel,
    @JsonKey(name: 'unread_count') @Default(0) int unreadCount,
  }) = _ConversationModel;

  factory ConversationModel.fromJson(Map<String, dynamic> json) => _$ConversationModelFromJson(json);
}
