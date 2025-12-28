import 'package:waifu/features/memory/data/database/app_database.dart';
import 'package:waifu/features/soul/domain/entities/chat_message.dart';
import 'package:waifu/features/soul/domain/entities/emotion.dart';

/// 记忆仓库
class MemoryRepository {
  final AppDatabase _db;

  MemoryRepository(this._db);

  /// 保存对话消息
  Future<void> saveMessage(ChatMessage message) async {
    await _db.saveConversation(
      messageId: message.id,
      content: message.content,
      isUser: message.isUser,
      emotion: message.emotion?.name,
    );
  }

  /// 获取对话历史
  Future<List<ChatMessage>> getConversationHistory({int limit = 50}) async {
    final rows = await _db.getRecentConversations(limit: limit);
    return rows.reversed.map((row) => ChatMessage(
      id: row.messageId,
      content: row.content,
      isUser: row.isUser,
      timestamp: row.timestamp,
      emotion: row.emotion != null ? EmotionType.fromTag(row.emotion!) : null,
    )).toList();
  }

  /// 保存重要记忆
  Future<void> saveMemory(String content, {double importance = 0.5}) async {
    await _db.saveMemory(content: content, importance: importance);
  }

  /// 搜索相关记忆 (用于 RAG)
  Future<List<String>> searchRelevantMemories(String query, {int limit = 5}) async {
    final memories = await _db.searchMemories(query, limit: limit);
    return memories.map((m) => m.content).toList();
  }

  /// 获取重要记忆摘要
  Future<String> getMemorySummary({int limit = 5}) async {
    final memories = await _db.getImportantMemories(limit: limit);
    if (memories.isEmpty) return '';
    
    return '【记忆】\n${memories.map((m) => '- ${m.content}').join('\n')}';
  }

  /// 清空对话历史
  Future<void> clearHistory() async {
    await _db.clearConversations();
  }
}
