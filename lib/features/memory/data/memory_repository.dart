import 'package:lumi/core/utils/logger.dart';
import 'package:lumi/features/memory/data/database/app_database.dart';
import 'package:lumi/features/memory/domain/memory_compactor.dart';
import 'package:lumi/features/soul/domain/entities/chat_message.dart';
import 'package:lumi/features/soul/domain/entities/emotion.dart';

/// 记忆仓库
/// ## 职责
/// 1. 对话消息的 CRUD
/// 2. 长期记忆的存储与检索
/// 3. 为 RAG 提供相关记忆
/// 4. 记忆压缩与清理
class MemoryRepository {
  final AppDatabase _db;
  final MemoryCompactor _compactor = MemoryCompactor();

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
    return rows.reversed
        .map(
          (row) => ChatMessage(
            id: row.messageId,
            content: row.content,
            isUser: row.isUser,
            timestamp: row.timestamp,
            emotion: row.emotion != null
                ? EmotionType.fromTag(row.emotion!)
                : null,
          ),
        )
        .toList();
  }

  /// 保存重要记忆
  Future<void> saveMemory(String content, {double importance = 0.5}) async {
    await _db.saveMemory(content: content, importance: importance);
  }

  /// 搜索相关记忆 (用于 RAG)
  ///
  /// 策略：
  /// 1. 提取查询中的关键词
  /// 2. 在记忆中搜索包含这些关键词的内容
  /// 3. 按重要性排序返回
  Future<List<String>> searchRelevantMemories(
    String query, {
    int limit = 10,
  }) async {
    // 提取关键词（简单分词）
    final keywords = _extractKeywords(query);

    if (keywords.isEmpty) {
      // 没有关键词，返回最重要的记忆
      final memories = await _db.getImportantMemories(limit: limit);
      return memories.map((m) => m.content).toList();
    }

    // 搜索包含任意关键词的记忆
    final allMatches = <Memory>[];
    for (final keyword in keywords) {
      final matches = await _db.searchMemories(keyword, limit: limit);
      for (final match in matches) {
        if (!allMatches.any((m) => m.id == match.id)) {
          allMatches.add(match);
        }
      }
    }

    // 按重要性排序
    allMatches.sort((a, b) => b.importance.compareTo(a.importance));

    return allMatches.take(limit).map((m) => m.content).toList();
  }

  /// 提取关键词
  ///
  /// 混合策略：中文使用 Bigram 切分，非中文按空格分割
  List<String> _extractKeywords(String text) {
    // 停用词列表
    const stopWords = {
      '的',
      '了',
      '是',
      '在',
      '我',
      '你',
      '他',
      '她',
      '它',
      '这',
      '那',
      '有',
      '和',
      '与',
      '或',
      '但',
      '如果',
      '什么',
      '怎么',
      '为什么',
      '哪里',
      '谁',
      '吗',
      '呢',
      '啊',
      '好',
      '很',
      '太',
      '真',
      '都',
      '也',
      '就',
      '还',
      '又',
    };

    // 清理标点符号
    final cleanText = text.replaceAll(
      RegExp('[，。！？、；：“”‘’（）\\[\\]【】:,.\\s]+'),
      ' ',
    );

    // 混合分词策略：空格分割 + 中文 Bigram
    final words = <String>{};

    for (final segment in cleanText.split(' ')) {
      if (segment.isEmpty) continue;

      // 如果是纯中文片段，使用 Bigram 切分
      if (RegExp(r'^[\u4e00-\u9fa5]+$').hasMatch(segment)) {
        // 先保留完整词（如果长度 >= 2）
        if (segment.length >= 2 && !stopWords.contains(segment)) {
          words.add(segment);
        }
        // Bigram 切分
        for (var i = 0; i < segment.length - 1; i++) {
          final bigram = segment.substring(i, i + 2);
          if (!stopWords.contains(bigram)) {
            words.add(bigram);
          }
        }
      } else if (segment.length >= 2 && !stopWords.contains(segment)) {
        // 非中文（英文等）直接保留
        words.add(segment);
      }
    }

    return words.take(10).toList(); // 最多 10 个关键词
  }

  /// 获取重要记忆摘要
  Future<String> getMemorySummary({int limit = 10}) async {
    final memories = await _db.getImportantMemories(limit: limit);
    if (memories.isEmpty) return '';

    return '【记忆】\n${memories.map((m) => '- ${m.content}').join('\n')}';
  }

  /// 清空对话历史
  Future<void> clearHistory() async {
    await _db.clearConversations();
  }

  /// 获取所有记忆（用于压缩分析）
  Future<List<MemoryItem>> getAllMemories() async {
    final memories = await _db.getImportantMemories(limit: 1000);
    return memories
        .map(
          (m) => MemoryItem(
            id: m.id,
            content: m.content,
            importance: m.importance,
            createdAt: m.createdAt,
            lastAccessedAt: m.lastAccessedAt,
            accessCount: m.accessCount,
          ),
        )
        .toList();
  }

  /// 检查是否存在相似记忆
  ///
  /// 在保存新记忆前调用，避免重复
  Future<bool> hasSimilarMemory(String content) async {
    final memories = await getAllMemories();
    for (final memory in memories) {
      if (_compactor.areSimilar(content, memory.content)) {
        return true;
      }
    }
    return false;
  }

  /// 保存记忆（带去重检查）
  ///
  /// 如果已存在相似记忆，则更新其重要性而不是新增
  Future<void> saveMemoryWithDedup(
    String content, {
    double importance = 0.5,
  }) async {
    final memories = await getAllMemories();

    // 查找相似记忆
    for (final memory in memories) {
      if (_compactor.areSimilar(content, memory.content)) {
        // 已存在相似记忆，更新重要性（取较高值）
        if (importance > memory.importance) {
          await _db.updateMemoryImportance(memory.id, importance);
          AppLogger.d('Updated existing memory importance: ${memory.id}');
        }
        // 更新访问时间
        await _db.touchMemory(memory.id);
        return;
      }
    }

    // 没有相似记忆，新增
    await _db.saveMemory(content: content, importance: importance);
  }

  /// 执行记忆压缩
  ///
  /// 返回压缩结果，包括合并和清理的记忆数量
  Future<CompactionResult> compactMemories({bool dryRun = true}) async {
    final memories = await getAllMemories();
    final result = _compactor.compact(memories);

    if (!dryRun) {
      // 执行实际的删除操作
      for (final merge in result.mergeResults) {
        for (final item in merge.remove) {
          await _db.deleteMemory(item.id);
          AppLogger.d('Deleted merged memory: ${item.id}');
        }
      }

      for (final item in result.cleanupCandidates) {
        // 避免重复删除（可能已在合并中删除）
        final alreadyRemoved = result.mergeResults.any(
          (m) => m.remove.any((r) => r.id == item.id),
        );
        if (!alreadyRemoved) {
          await _db.deleteMemory(item.id);
          AppLogger.d('Deleted low-importance memory: ${item.id}');
        }
      }
    }

    AppLogger.d('Compaction result: $result');
    return result;
  }

  /// 获取记忆统计信息
  Future<MemoryStats> getStats() async {
    final memories = await getAllMemories();
    if (memories.isEmpty) {
      return const MemoryStats(
        totalCount: 0,
        avgImportance: 0,
        oldestDate: null,
        newestDate: null,
      );
    }

    final totalImportance = memories.fold<double>(
      0,
      (sum, m) => sum + m.importance,
    );

    memories.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return MemoryStats(
      totalCount: memories.length,
      avgImportance: totalImportance / memories.length,
      oldestDate: memories.first.createdAt,
      newestDate: memories.last.createdAt,
    );
  }
}

/// 记忆统计信息
class MemoryStats {
  final int totalCount;
  final double avgImportance;
  final DateTime? oldestDate;
  final DateTime? newestDate;

  const MemoryStats({
    required this.totalCount,
    required this.avgImportance,
    required this.oldestDate,
    required this.newestDate,
  });

  @override
  String toString() =>
      'MemoryStats(count: $totalCount, avgImportance: ${avgImportance.toStringAsFixed(2)})';
}
