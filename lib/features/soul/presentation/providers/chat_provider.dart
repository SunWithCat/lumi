import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:waifu/core/config/api_config.dart';
import 'package:waifu/core/utils/logger.dart';
import 'package:waifu/features/memory/data/memory_repository.dart';
import 'package:waifu/features/memory/presentation/providers/memory_provider.dart';
import 'package:waifu/features/soul/data/llm_client.dart';
import 'package:waifu/features/soul/data/response_parser.dart';
import 'package:waifu/features/soul/domain/entities/chat_message.dart';
import 'package:waifu/features/soul/domain/entities/emotion.dart';
import 'package:waifu/features/soul/domain/entities/persona_config.dart';
import 'package:waifu/features/soul/presentation/providers/persona_provider.dart';

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
  final _uuid = const Uuid();

  ChatNotifier({
    LLMClient? llmClient,
    MemoryRepository? memoryRepo,
    PersonaConfig persona = PersonaConfig.defaultPersona,
  })  : _llmClient = llmClient,
        _memoryRepo = memoryRepo,
        _persona = persona,
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
        // 构建上下文 - 取最近的消息（排除刚添加的用户消息）
        final recentMessages = state.messages.length > 1
            ? state.messages.sublist(0, state.messages.length - 1)
            : <ChatMessage>[];
        
        // 取最近 20 条作为上下文
        final contextMessages = recentMessages.length > 2000
            ? recentMessages.sublist(recentMessages.length - 2000)
            : recentMessages;

        final history = [
          ...contextMessages.map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              }),
          // 添加当前用户消息
          {'role': 'user', 'content': content},
        ];

        AppLogger.d('Sending ${history.length} messages to LLM');
        for (var i = 0; i < history.length; i++) {
          AppLogger.d('  [$i] ${history[i]['role']}: ${history[i]['content']}');
        }

        // 获取相关记忆 (RAG)
        String memorySummary = '';
        if (_memoryRepo != null) {
          memorySummary = await _memoryRepo.getMemorySummary(limit: 3);
        }

        // 构建增强的系统提示
        final enhancedPrompt = memorySummary.isNotEmpty
            ? '${_persona.systemPrompt}\n\n$memorySummary'
            : _persona.systemPrompt;

        final response = await _llmClient.chat(
          systemPrompt: enhancedPrompt,
          messages: history,
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
        final mock = mockResponses[state.messages.length % mockResponses.length];
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
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 提取重要信息保存为记忆
  Future<void> _extractAndSaveMemory(String userInput, String aiResponse) async {
    if (_memoryRepo == null) return;

    // 简单规则：如果用户提到"喜欢"、"讨厌"、"名字"等关键词，保存为记忆
    final keywords = ['喜欢', '讨厌', '名字叫', '我是', '生日', '工作', '住在'];
    for (final keyword in keywords) {
      if (userInput.contains(keyword)) {
        await _memoryRepo.saveMemory(
          '用户说: $userInput',
          importance: 0.8,
        );
        break;
      }
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
  
  // 从 AsyncValue 中获取人格配置，如果还在加载则使用默认
  final persona = personaAsync.valueOrNull ?? PersonaConfig.sakura;
  
  LLMClient? llmClient;
  if (ApiConfig.isConfigured) {
    llmClient = LLMClient(
      baseUrl: ApiConfig.baseUrl,
      apiKey: ApiConfig.apiKey,
      model: ApiConfig.model,
    );
  }

  final notifier = ChatNotifier(
    llmClient: llmClient,
    memoryRepo: memoryRepo,
    persona: persona,
  );

  // 加载历史对话
  notifier.loadHistory();

  return notifier;
});
