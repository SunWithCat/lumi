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

/// 聊天状态
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final EmotionType currentEmotion;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.currentEmotion = EmotionType.neutral,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    EmotionType? currentEmotion,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      currentEmotion: currentEmotion ?? this.currentEmotion,
      error: error,
    );
  }
}

/// 聊天 Provider
class ChatNotifier extends StateNotifier<ChatState> {
  final LLMClient? _llmClient;
  final MemoryRepository? _memoryRepo;
  final PersonaConfig _persona;
  final LLMSettings _llmSettings;
  final _uuid = const Uuid();
  final _contextManager = ContextManager();
  final _memoryEvaluator = MemoryEvaluator();

  ChatNotifier({
    LLMClient? llmClient,
    MemoryRepository? memoryRepo,
    PersonaConfig persona = PersonaConfig.defaultPersona,
    LLMSettings llmSettings = const LLMSettings(),
  }) : _llmClient = llmClient,
       _memoryRepo = memoryRepo,
       _persona = persona,
       _llmSettings = llmSettings,
       super(const ChatState());

  /// 初始化：加载历史对话
  Future<void> loadHistory() async {
    if (_memoryRepo == null) return;

    final history = await _memoryRepo.getConversationHistory(limit: 50);
    if (history.isNotEmpty) {
      state = state.copyWith(messages: history);
    }
  }

  /// 发送消息
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // 添加用户消息
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    // 保存到数据库
    await _memoryRepo?.saveMessage(userMessage);

    try {
      String responseText;
      EmotionType emotion;

      if (_llmClient != null) {
        // 获取相关记忆 (RAG)
        List<String> relevantMemories = [];
        if (_memoryRepo != null) {
          relevantMemories = await _memoryRepo.searchRelevantMemories(
            content,
            limit: 5,
          );
        }

        // 使用上下文管理器构建上下文
        final context = _contextManager.buildContext(
          allMessages: state.messages.sublist(
            0,
            state.messages.length - 1,
          ), // 排除刚添加的用户消息
          currentInput: content,
          memories: relevantMemories,
        );

        AppLogger.d(
          'Context: ${context.includedMessageCount}/${context.totalMessageCount} messages, hasMemories: ${context.hasMemories}',
        );

        // 构建增强的系统提示
        final enhancedPrompt = context.hasMemories
            ? '${_persona.systemPrompt}\n\n${context.memorySummary}'
            : _persona.systemPrompt;

        final response = await _llmClient.chat(
          systemPrompt: enhancedPrompt,
          messages: context.messages,
          temperature: _llmSettings.temperature,
          maxTokens: _llmSettings.maxTokens,
          topP: _llmSettings.topP,
        );

        final parsed = ResponseParser.parse(response);
        responseText = parsed.text;
        emotion = parsed.emotion;
      } else {
        // 模拟响应
        await Future.delayed(const Duration(milliseconds: 800));
        final mockResponses = [
          ('主人好呀~ 今天过得怎么样？(≧▽≦)', EmotionType.happy),
          ('嗯嗯，我在听呢~ 继续说吧！', EmotionType.curious),
          ('主人说的好有趣哦！', EmotionType.happy),
        ];
        final mock =
            mockResponses[state.messages.length % mockResponses.length];
        responseText = mock.$1;
        emotion = mock.$2;
      }

      // 添加 AI 回复
      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        content: responseText,
        isUser: false,
        timestamp: DateTime.now(),
        emotion: emotion,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        currentEmotion: emotion,
      );

      // 保存到数据库
      await _memoryRepo?.saveMessage(aiMessage);

      // 提取并保存重要记忆
      await _extractAndSaveMemory(content, responseText);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 提取重要信息保存为记忆
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

  /// 清空对话
  Future<void> clearMessages() async {
    await _memoryRepo?.clearHistory();
    state = const ChatState();
  }

  @override
  void dispose() {
    _llmClient?.dispose();
    super.dispose();
  }
}

/// Provider 定义
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
  );

  // 加载历史对话
  notifier.loadHistory();

  return notifier;
});
