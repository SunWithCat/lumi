import 'package:lumi/features/soul/domain/entities/chat_message.dart';

/// 上下文管理器
/// 
/// 负责构建发送给 LLM 的上下文，包括：
/// 1. 最近对话历史（滑动窗口）
/// 2. 相关长期记忆（RAG 检索）
/// 3. Token 预算控制
/// 
/// ## 为什么需要上下文管理器？
/// 
/// LLM 有 token 限制（如 DeepSeek 的 64K），我们不能把所有历史都发过去。
/// 需要智能选择"最相关"的上下文，让 AI 既能记住重要信息，又不超出限制。
/// 
/// ## 上下文构建策略
/// 
/// ```
/// ┌─────────────────────────────────────────────────────────────┐
/// │                    LLM 上下文结构                            │
/// ├─────────────────────────────────────────────────────────────┤
/// │  1. System Prompt (人格设定)           ~500 tokens          │
/// │  2. 长期记忆摘要 (RAG 检索)            ~200 tokens          │
/// │  3. 最近对话历史 (滑动窗口)            ~1000 tokens         │
/// │  4. 当前用户输入                       ~100 tokens          │
/// ├─────────────────────────────────────────────────────────────┤
/// │  预留给 AI 回复                        ~500 tokens          │
/// └─────────────────────────────────────────────────────────────┘
/// ```
class ContextManager {
  /// 默认配置
  static const int defaultMaxContextMessages = 20;
  static const int defaultMaxMemories = 5;
  static const int defaultEstimatedTokensPerMessage = 50;
  
  final int maxContextMessages;
  final int maxMemories;
  
  ContextManager({
    this.maxContextMessages = defaultMaxContextMessages,
    this.maxMemories = defaultMaxMemories,
  });

  /// 构建对话上下文
  /// 
  /// [allMessages] 所有历史消息
  /// [currentInput] 当前用户输入
  /// [memories] 相关记忆列表
  /// 
  /// 返回格式化的消息列表，可直接发送给 LLM
  ContextResult buildContext({
    required List<ChatMessage> allMessages,
    required String currentInput,
    List<String> memories = const [],
  }) {
    // 1. 选择最近的对话（滑动窗口）
    final recentMessages = _selectRecentMessages(allMessages);
    
    // 2. 构建记忆摘要
    final memorySummary = _buildMemorySummary(memories);
    
    // 3. 转换为 LLM 消息格式
    final contextMessages = recentMessages.map((m) => {
      'role': m.isUser ? 'user' : 'assistant',
      'content': m.content,
    }).toList();
    
    // 4. 添加当前用户输入
    contextMessages.add({
      'role': 'user',
      'content': currentInput,
    });
    
    return ContextResult(
      messages: contextMessages,
      memorySummary: memorySummary,
      includedMessageCount: recentMessages.length,
      totalMessageCount: allMessages.length,
    );
  }

  /// 选择最近的消息（滑动窗口策略）
  /// 
  /// 策略：
  /// 1. 优先保留最近的消息
  /// 2. 确保对话成对（用户-AI）
  /// 3. 不超过 maxContextMessages
  List<ChatMessage> _selectRecentMessages(List<ChatMessage> allMessages) {
    if (allMessages.isEmpty) return [];
    
    // 取最近 N 条
    final startIndex = allMessages.length > maxContextMessages
        ? allMessages.length - maxContextMessages
        : 0;
    
    return allMessages.sublist(startIndex);
  }

  /// 构建记忆摘要
  /// 
  /// 将检索到的记忆格式化为 LLM 可理解的文本
  String _buildMemorySummary(List<String> memories) {
    if (memories.isEmpty) return '';
    
    final buffer = StringBuffer();
    buffer.writeln('【关于用户的记忆】');
    for (final memory in memories.take(maxMemories)) {
      buffer.writeln('• $memory');
    }
    return buffer.toString();
  }

  /// 估算 token 数量（粗略估计）
  /// 
  /// 中文大约 1.5 字符 = 1 token
  /// 英文大约 4 字符 = 1 token
  int estimateTokens(String text) {
    // 简单估算：中文按 1.5 字符/token，英文按 4 字符/token
    // 这里用一个折中值
    return (text.length / 2).ceil();
  }
}

/// 上下文构建结果
class ContextResult {
  /// 格式化的消息列表（可直接发送给 LLM）
  final List<Map<String, String>> messages;
  
  /// 记忆摘要（需要注入到 system prompt）
  final String memorySummary;
  
  /// 实际包含的历史消息数
  final int includedMessageCount;
  
  /// 总消息数
  final int totalMessageCount;

  const ContextResult({
    required this.messages,
    required this.memorySummary,
    required this.includedMessageCount,
    required this.totalMessageCount,
  });

  /// 是否有记忆被注入
  bool get hasMemories => memorySummary.isNotEmpty;
  
  /// 是否有历史被截断
  bool get isTruncated => includedMessageCount < totalMessageCount;
}
