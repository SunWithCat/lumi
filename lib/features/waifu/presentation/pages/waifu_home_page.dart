import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waifu/features/body/presentation/controllers/live2d_controller.dart';
import 'package:waifu/features/body/presentation/providers/live2d_provider.dart';
import 'package:waifu/features/body/presentation/widgets/live2d_view.dart';
import 'package:waifu/features/chat/presentation/widgets/chat_input.dart';
import 'package:waifu/features/soul/domain/entities/emotion.dart';
import 'package:waifu/features/soul/presentation/providers/chat_provider.dart';

class WaifuHomePage extends ConsumerStatefulWidget {
  const WaifuHomePage({super.key});

  @override
  ConsumerState<WaifuHomePage> createState() => _WaifuHomePageState();
}

class _WaifuHomePageState extends ConsumerState<WaifuHomePage> {
  late Live2DController _live2dController;
  bool _live2dInitialized = false;

  @override
  void initState() {
    super.initState();
    _live2dController = ref.read(live2dControllerProvider);
    _initLive2D();
  }

  Future<void> _initLive2D() async {
    // 初始化 Live2D 渲染器
    final success = await _live2dController.initialize(width: 512, height: 512);
    if (success) {
      // 加载 hiyori 模型
      await _live2dController.loadModel('live2d/runtime/hiyori_free_t08.model3.json');
      setState(() => _live2dInitialized = true);
    }
  }

  void _onHitAreaTapped(String hitArea) {
    // 根据点击区域播放动作
    switch (hitArea) {
      case 'head':
        _live2dController.playMotion('tap_head');
        break;
      case 'body':
        _live2dController.playMotion('tap_body');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // 监听情感变化，更新 Live2D 表情
    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (prev?.currentEmotion != next.currentEmotion && _live2dInitialized) {
        _updateLive2DExpression(next.currentEmotion);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Live2D 区域
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // 背景渐变
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2D1B4E), Color(0xFF1A1A2E)],
                      ),
                    ),
                  ),
                  // Live2D 视图
                  Center(
                    child: SizedBox(
                      width: 300,
                      height: 400,
                      child: Live2DView(
                        controller: _live2dController,
                        onHitAreaTapped: _onHitAreaTapped,
                      ),
                    ),
                  ),
                  // 情感指示器
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _EmotionIndicator(emotion: chatState.currentEmotion),
                  ),
                ],
              ),
            ),
            // 对话区域
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: chatState.messages.isEmpty
                          ? const Center(
                              child: Text('和我聊聊天吧~', style: TextStyle(color: Colors.white54)),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: chatState.messages.length,
                              itemBuilder: (context, index) {
                                final msg = chatState.messages[index];
                                return _MessageBubble(
                                  text: msg.content,
                                  isUser: msg.isUser,
                                  emotion: msg.emotion,
                                );
                              },
                            ),
                    ),
                    if (chatState.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text('正在思考中...', style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      ),
                    if (chatState.error != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(chatState.error!, style: const TextStyle(color: Colors.redAccent)),
                      ),
                    ChatInput(onSend: (text) => ref.read(chatProvider.notifier).sendMessage(text)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateLive2DExpression(EmotionType emotion) {
    // 情感到 Live2D 表情的映射
    final expressionMap = {
      EmotionType.happy: 'smile',
      EmotionType.sad: 'sad',
      EmotionType.angry: 'angry',
      EmotionType.surprised: 'surprised',
      EmotionType.shy: 'shy',
      EmotionType.curious: 'think',
      EmotionType.loving: 'love',
      EmotionType.worried: 'worried',
      EmotionType.neutral: 'neutral',
    };

    final expression = expressionMap[emotion] ?? 'neutral';
    _live2dController.setExpression(expression);
  }
}

class _EmotionIndicator extends StatelessWidget {
  final EmotionType emotion;
  const _EmotionIndicator({required this.emotion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emotion.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 4),
          Text(emotion.label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final EmotionType? emotion;

  const _MessageBubble({required this.text, required this.isUser, this.emotion});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).colorScheme.primary : Colors.white12,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: const TextStyle(color: Colors.white)),
            if (!isUser && emotion != null) ...[
              const SizedBox(height: 4),
              Text(emotion!.emoji, style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
