import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waifu/features/body/domain/emotion_motion_mapper.dart';
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
    final success = await _live2dController.initialize(width: 512, height: 512);
    debugPrint('Live2D initialize: $success');
    if (success) {
      // 加载 Pro 模型
      final modelLoaded = await _live2dController.loadModel('hiyori_pro_zh/runtime/hiyori_pro_t11.model3.json');
      debugPrint('Live2D model loaded: $modelLoaded, controller.isModelLoaded: ${_live2dController.isModelLoaded}');
      setState(() => _live2dInitialized = true);
    }
  }

  void _onHitAreaTapped(String hitArea) {
    switch (hitArea) {
      case 'Body':
        _live2dController.playMotion('Tap@Body');
        break;
      default:
        _live2dController.playMotion('Tap');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // 监听情感变化，更新 Live2D 动作
    ref.listen<ChatState>(chatProvider, (prev, next) {
      debugPrint('Emotion: ${prev?.currentEmotion} -> ${next.currentEmotion}, init=$_live2dInitialized');
      if (prev?.currentEmotion != next.currentEmotion && _live2dInitialized) {
        debugPrint('Playing emotion motion: ${next.currentEmotion}');
        _playEmotionMotion(next.currentEmotion);
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: () => _showClearDialog(context),
            tooltip: '清除对话',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Column(
          children: [
            // Live2D 区域
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2D1B4E), Color(0xFF1A1A2E)],
                      ),
                    ),
                  ),
                  Center(
                    child: SizedBox(
                      width: 350,
                      height: 350,
                      child: Live2DView(
                        controller: _live2dController,
                        onHitAreaTapped: _onHitAreaTapped,
                      ),
                    ),
                  ),
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

  void _playEmotionMotion(EmotionType emotion) {
    final mapping = EmotionMotionMapper.getMotionForEmotion(emotion);
    debugPrint('_playEmotionMotion: emotion=$emotion, mapping=${mapping.group}[${mapping.index}], isModelLoaded=${_live2dController.isModelLoaded}');
    _live2dController.playMotion(mapping.group, index: mapping.index, priority: mapping.priority);
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除对话'),
        content: const Text('确定要清除所有对话记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearMessages();
              Navigator.pop(ctx);
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
