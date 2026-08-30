import 'emotion.dart';

/// 聊天消息
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final EmotionType? emotion;
  final String? thinkingContent; // AI 思维链内容

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.emotion,
    this.thinkingContent,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    EmotionType? emotion,
    String? thinkingContent,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      emotion: emotion ?? this.emotion,
      thinkingContent: thinkingContent ?? this.thinkingContent,
    );
  }
}
