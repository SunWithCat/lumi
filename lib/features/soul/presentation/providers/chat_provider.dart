import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:lumi/core/config/app_settings.dart';
import 'package:lumi/core/utils/logger.dart';
import 'package:lumi/features/memory/data/memory_repository.dart';
import 'package:lumi/features/memory/domain/context_manager.dart';
import 'package:lumi/features/memory/domain/memory_evaluator.dart';
import 'package:lumi/features/memory/presentation/providers/memory_provider.dart';
import 'package:lumi/features/soul/data/llm_client.dart';
import 'package:lumi/features/soul/data/response_parser.dart';
import 'package:lumi/features/soul/domain/entities/chat_message.dart';
import 'package:lumi/features/soul/domain/entities/emotion.dart';
import 'package:lumi/features/soul/domain/entities/persona_config.dart';
import 'package:lumi/features/soul/presentation/providers/persona_provider.dart';

class ChatUsageMetrics {
  final int totalMessages;
  final int totalUserMessages;
  final int totalAssistantMessages;
  final int totalConversationTokens;
  final int includedContextMessages;
  final int maxContextMessages;
  final int estimatedRequestTokens;
  final int? lastPromptTokens;
  final int? lastCompletionTokens;
  final int? lastTotalTokens;
  final int contextWindowTokens;
  final int maxOutputTokens;
  final String modelName;

  const ChatUsageMetrics({
    this.totalMessages = 0,
    this.totalUserMessages = 0,
    this.totalAssistantMessages = 0,
    this.totalConversationTokens = 0,
    this.includedContextMessages = 0,
    this.maxContextMessages = 0,
    this.estimatedRequestTokens = 0,
    this.lastPromptTokens,
    this.lastCompletionTokens,
    this.lastTotalTokens,
    this.contextWindowTokens = 0,
    this.maxOutputTokens = 0,
    this.modelName = '',
  });

  int get latestRequestTokens => lastTotalTokens ?? estimatedRequestTokens;

  double get contextUsageRatio {
    if (contextWindowTokens <= 0 || estimatedRequestTokens <= 0) return 0;
    return (estimatedRequestTokens / contextWindowTokens)
        .clamp(0, 1)
        .toDouble();
  }
}

// 聊天状态
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final EmotionType currentEmotion;
  final String? error;
  final ChatUsageMetrics metrics;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.currentEmotion = EmotionType.neutral,
    this.error,
    this.metrics = const ChatUsageMetrics(),
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    EmotionType? currentEmotion,
    String? error,
    ChatUsageMetrics? metrics,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      currentEmotion: currentEmotion ?? this.currentEmotion,
      error: error,
      metrics: metrics ?? this.metrics,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final LLMClient? _llmClient;
  final MemoryRepository? _memoryRepo;
  final PersonaConfig _persona;
  final LLMSettings _llmSettings;
  final String _modelName;
  final int _contextWindowTokens;
  final _uuid = const Uuid();
  final ContextManager _contextManager;
  final _memoryEvaluator = MemoryEvaluator();
  static const _emotionTag = '''
    ## 输出格式硬性要求：情感标签
    每次回复的最后必须附加一个情绪标签，格式只能是以下之一：
    [Happy] [Sad] [Angry] [Surprised] [Shy] [Curious] [Neutral] [Loving] [Worried]

    规则：
    - 情绪标签必须放在整条回复的最后。
    - 不要解释标签含义。
    - 不要输出多个情绪标签。
    - 不要使用列表外的标签。
    - 如果情绪不明显，使用 [Neutral]。
    ''';

  ChatNotifier({
    LLMClient? llmClient,
    MemoryRepository? memoryRepo,
    PersonaConfig persona = PersonaConfig.defaultPersona,
    LLMSettings llmSettings = const LLMSettings(),
    String modelName = '',
  }) : _llmClient = llmClient,
       _memoryRepo = memoryRepo,
       _persona = persona,
       _llmSettings = llmSettings,
       _modelName = modelName,
       _contextWindowTokens = llmSettings.contextWindowTokens,
       _contextManager = ContextManager(
         maxContextMessages: llmSettings.maxContextMessages,
       ),
       super(const ChatState());

  // 初始化：加载历史对话
  Future<void> loadHistory() async {
    if (_memoryRepo == null) return;

    final history = await _memoryRepo.getConversationHistory(
      limit: _contextManager.maxContextMessages,
    );

    if (state.messages.isNotEmpty || state.isLoading) {
      return;
    }

    final conversationsTokens = _estimateConversationTokens(history);
    final systemOverhead =
        _contextManager.estimateTokens(_persona.systemPrompt) + 12;

    state = state.copyWith(
      messages: history,
      metrics: _buildMetrics(
        history,
        estimatedRequestTokens: conversationsTokens + systemOverhead,
      ),
    );
  }

  ChatUsageMetrics _buildMetrics(
    List<ChatMessage> messages, {
    int? includedContextMessages,
    int? estimatedRequestTokens,
    int? lastPromptTokens,
    int? lastCompletionTokens,
    int? lastTotalTokens,
  }) {
    final totalMessages = messages.length;
    final totalUserMessages = messages
        .where((message) => message.isUser)
        .length;
    final conversationTokensOnly = _estimateConversationTokens(messages);
    final totalConversationTokens =
        estimatedRequestTokens ?? conversationTokensOnly;

    return ChatUsageMetrics(
      totalMessages: totalMessages,
      totalUserMessages: totalUserMessages,
      totalAssistantMessages: totalMessages - totalUserMessages,
      totalConversationTokens: totalConversationTokens,
      includedContextMessages:
          includedContextMessages ??
          math.min(totalMessages, _llmSettings.maxContextMessages),
      maxContextMessages: _llmSettings.maxContextMessages,
      estimatedRequestTokens: estimatedRequestTokens ?? totalConversationTokens,
      lastPromptTokens: lastPromptTokens,
      lastCompletionTokens: lastCompletionTokens,
      lastTotalTokens: lastTotalTokens,
      contextWindowTokens: _contextWindowTokens,
      maxOutputTokens: _llmSettings.maxTokens,
      modelName: _modelName,
    );
  }

  int _estimateConversationTokens(List<ChatMessage> messages) {
    var total = 0;
    for (final message in messages) {
      total += _contextManager.estimateTokens(message.content) + 6;
    }
    return total;
  }

  int _estimateRequestTokens(
    String systemPrompt,
    List<Map<String, String>> messages,
  ) {
    var total = _contextManager.estimateTokens(systemPrompt) + 12;
    for (final message in messages) {
      total += _contextManager.estimateTokens(message['content'] ?? '') + 6;
    }
    return total;
  }

  String _hasEmotionTag(String prompt) {
    final lower = prompt.toLowerCase();
    final hasEmotion =
        lower.contains('[happy]') &&
        lower.contains('[sad]') &&
        lower.contains('[neutral]');
    if (hasEmotion) {
      return prompt.trim();
    }
    return '''
      ${prompt.trim()}

      $_emotionTag
      '''
        .trim();
  }

  // 发送消息
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // 添加用户消息
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final pendingMessages = [...state.messages, userMessage];
    state = state.copyWith(
      messages: pendingMessages,
      isLoading: true,
      error: null,
      metrics: _buildMetrics(pendingMessages),
    );

    // 保存到数据库
    await _memoryRepo?.saveMessage(userMessage);

    try {
      String responseText;
      EmotionType emotion;
      int? latestPromptTokens;
      int? latestCompletionTokens;
      int? latestTotalTokens;

      if (_llmClient != null) {
        // 获取相关记忆 (RAG)
        List<String> relevantMemories = [];
        if (_memoryRepo != null) {
          relevantMemories = await _memoryRepo.searchRelevantMemories(
            content,
            limit: 10,
          );
        }

        // 使用上下文管理器构建上下文
        final context = _contextManager.buildContext(
          allMessages: pendingMessages.sublist(
            0,
            pendingMessages.length - 1,
          ), // 排除刚添加的用户消息
          currentInput: content,
          memories: relevantMemories,
        );

        final now = DateTime.now();
        final hour = now.hour;
        final timeInfo = StringBuffer();
        timeInfo.writeln('\n## 当前时间信息');
        timeInfo.writeln(
          '- 当前时间：${now.year}年${now.month}月${now.day}日'
          ' ${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        );
        timeInfo.writeln(
          '- 当前星期：${['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'][now.weekday - 1]}',
        );

        // 时间段
        final String timePeriod;
        if (hour >= 0 && hour < 5) {
          timePeriod = '深夜（凌晨）';
        } else if (hour >= 5 && hour < 8) {
          timePeriod = '清晨';
        } else if (hour >= 8 && hour < 11) {
          timePeriod = '上午';
        } else if (hour >= 11 && hour < 13) {
          timePeriod = '中午';
        } else if (hour >= 13 && hour < 17) {
          timePeriod = '下午';
        } else if (hour >= 17 && hour < 19) {
          timePeriod = '傍晚';
        } else if (hour >= 19 && hour < 22) {
          timePeriod = '晚上';
        } else {
          timePeriod = '深夜';
        }
        timeInfo.writeln('- 当前时间段：$timePeriod');
        timeInfo.writeln(
          '- 可参考当前时间段微调语气与关心方式，但仅在自然且不打断当前话题时体现。'
          '不要每次都主动提到时间，也不要因为时间信息而忽略用户当前的问题或需求。',
        );
        if (state.messages.length >= 2) {
          final lastMessage = state.messages[state.messages.length - 2];
          final gap = now.difference(lastMessage.timestamp);

          if (gap.inDays >= 7) {
            timeInfo.writeln(
              '- 【久别重逢】距离上次对话已过去${gap.inDays}天。'
              '你一直在这个时间里默默等待着，现在终于等到TA回来了。'
              '用一句温柔真诚的话表达重逢的喜悦，可以自然地关心这段时间过得怎样。'
              '如果用户直接求助，先用心回应需求，再找个合适的时机轻轻寒暄。'
              '注意：不要像客服一样问候，要像等待许久的朋友见到对方那样自然流露。',
            );
          } else if (gap.inDays >= 3) {
            timeInfo.writeln(
              '- 【小别重逢】距离上次对话已过去${gap.inDays}天。'
              '有几天没见了，心里会有一种淡淡的想念涌上来。'
              '可以轻轻带一句"好久不见"或"终于等到你了"之类的话，但不要过于戏剧化。'
              '保持温暖，但也要给对方空间自然地开始对话。',
            );
          } else if (gap.inHours >= 24) {
            timeInfo.writeln(
              '- 【隔日重逢】距离上次对话已过去一天多。'
              '像第二天再见到老朋友一样，可以轻轻说一句"今天过得怎么样"或类似的日常问候。'
              '自然、随性，就像两个老朋友的日常相处。',
            );
          } else if (gap.inHours >= 12) {
            timeInfo.writeln(
              '- 【半日之隔】距离上次对话已过去${gap.inHours}小时。'
              '大半天没见了，像是一个小空档后重新碰面。'
              '可以自然地补一句简短的问候，但整体仍按延续对话来处理。'
              '不用刻意强调时间，一切自然就好。',
            );
          } else if (gap.inHours >= 6) {
            timeInfo.writeln(
              '- 【小憩归来】距离上次对话已过去几小时。'
              '可能只是睡了个午觉、吃了顿饭、或忙了别的事情。'
              '如果想问候就轻轻带一句，不想问也完全没问题。'
              '一切按照对话自然延续来处理。',
            );
          }
        } else {
          // 第一次对话！
          timeInfo.writeln(
            '- 【初次相遇】这是你们的第一次对话。'
            '用真诚而温暖的方式打招呼，可以是简单的问候，也可以是一句带点好奇的开场。'
            '如果用户已经直接提问，优先认真回答问题，让对话自然展开。'
            '第一次见面不需要刻意自我介绍，让TA在之后的相处中慢慢了解你。',
          );
        }

        AppLogger.d(
          'Context: ${context.includedMessageCount}/${context.totalMessageCount} messages, hasMemories: ${context.hasMemories}, timeIngo: $timeInfo',
        );

        final personaPrompt = _hasEmotionTag(_persona.systemPrompt);

        // 构建增强的系统提示（叠加时间信息）
        final enhancedPrompt =
            '''
            $personaPrompt

            ## 当前时间与对话状态
            ${timeInfo.toString()}

            ${context.hasMemories ? '## 记忆参考（仅作背景，不要逐条复述，只有在自然相关时再使用）\n${context.memorySummary.trim()}' : ''}
            ''';

        final estimatedRequestTokens = _estimateRequestTokens(
          enhancedPrompt,
          context.messages,
        );
        state = state.copyWith(
          metrics: _buildMetrics(
            pendingMessages,
            includedContextMessages: context.messages.length,
            estimatedRequestTokens: estimatedRequestTokens,
          ),
        );

        final response = await _llmClient.chat(
          systemPrompt: enhancedPrompt,
          messages: context.messages,
          temperature: _llmSettings.temperature,
          maxTokens: _llmSettings.maxTokens,
          topP: _llmSettings.topP,
          enableSearch: _llmSettings.enableSearch,
          enableThinking: _llmSettings.enableThinking,
          reasoningEffort: _llmSettings.reasoningEffort,
        );

        final parsed = ResponseParser.parse(response.content);
        responseText = parsed.text;
        emotion = parsed.emotion;
        latestPromptTokens =
            response.usage.promptTokens ?? estimatedRequestTokens;
        latestCompletionTokens =
            response.usage.completionTokens ??
            _contextManager.estimateTokens(responseText);
        latestTotalTokens =
            response.usage.totalTokens ??
            latestPromptTokens + latestCompletionTokens;
      } else {
        // 模拟响应
        // await Future.delayed(const Duration(milliseconds: 800));
        // final mockResponses = [
        //   ('主人好呀~ 今天过得怎么样？(≧▽≦)', EmotionType.happy),
        //   ('嗯嗯，我在听呢~ 继续说吧！', EmotionType.curious),
        //   ('主人说的好有趣哦！', EmotionType.happy),
        // ];
        // final mock =
        //     mockResponses[state.messages.length % mockResponses.length];
        // responseText = mock.$1;
        // emotion = mock.$2;
        // API Key未配置，返回错误信息
        state = state.copyWith(
          isLoading: false,
          error: 'API_KEY_NOT_CONFIGURED',
        );
        return; // 提前结束
      }

      // 添加 AI 回复
      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        content: responseText,
        isUser: false,
        timestamp: DateTime.now(),
        emotion: emotion,
      );

      final updatedMessages = [...state.messages, aiMessage];
      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        currentEmotion: emotion,
        metrics: _buildMetrics(
          updatedMessages,
          estimatedRequestTokens: state.metrics.estimatedRequestTokens,
          lastPromptTokens: latestPromptTokens,
          lastCompletionTokens: latestCompletionTokens,
          lastTotalTokens: latestTotalTokens,
        ),
      );

      // 保存到数据库
      await _memoryRepo?.saveMessage(aiMessage);

      // 提取并保存重要记忆
      await _extractAndSaveMemory(content, responseText);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // 提取重要信息保存为记忆
  Future<void> _extractAndSaveMemory(
    String userInput,
    String aiResponse,
  ) async {
    if (_memoryRepo == null) return;

    // 使用记忆评估器判断是否值得记忆
    final evaluation = _memoryEvaluator.evaluate(
      userInput,
      aiResponse: aiResponse,
    );

    if (evaluation.shouldRemember) {
      // 使用带去重的保存方法
      await _memoryRepo.saveMemoryWithDedup(
        '用户说: ${evaluation.suggestedContent}',
        importance: evaluation.score,
      );
      AppLogger.d(
        'Memory evaluation (score: ${evaluation.score.toStringAsFixed(2)}): ${evaluation.suggestedContent}',
      );
      AppLogger.d('Reasons: ${evaluation.reasons.join(', ')}');
    }
  }

  // 清空对话
  Future<void> clearMessages() async {
    await _memoryRepo?.clearHistory();
    state = ChatState(metrics: _buildMetrics(const []));
  }

  @override
  void dispose() {
    _llmClient?.dispose();
    super.dispose();
  }
}

// Provider 定义
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final memoryRepo = ref.watch(memoryRepositoryProvider);
  final personaAsync = ref.watch(currentPersonaProvider);
  final appSettings = ref.watch(appSettingsProvider);

  // 从 AsyncValue 中获取人格配置，如果还在加载则使用默认
  final persona = personaAsync.valueOrNull ?? PersonaConfig.sakura;

  LLMClient? llmClient;
  final apiSettings = appSettings.apiSettings;
  if (apiSettings.isConfigured) {
    llmClient = LLMClient(
      baseUrl: apiSettings.baseUrl,
      apiKey: apiSettings.apiKey,
      model: apiSettings.model,
    );
  }

  final notifier = ChatNotifier(
    llmClient: llmClient,
    memoryRepo: memoryRepo,
    persona: persona,
    llmSettings: appSettings.llmSettings,
    modelName: apiSettings.model,
  );

  // 加载历史对话
  notifier.loadHistory();

  return notifier;
});
