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

  // 浪漫粉色调
  static const _gradientTop = Color(0xFFFFE4EC);
  static const _gradientBottom = Color(0xFFFFF5F7);
  static const _primaryPink = Color(0xFFFF85A2);
  static const _lightPink = Color(0xFFFFB6C8);
  // static const _softPink = Color(0xFFFFF0F3);

  @override
  void initState() {
    super.initState();
    _live2dController = ref.read(live2dControllerProvider);
    _initLive2D();
  }

  Future<void> _initLive2D() async {
    final success = await _live2dController.initialize(width: 512, height: 512);
    if (success) {
      final modelLoaded = await _live2dController.loadModel(
        'hiyori_pro_zh/runtime/hiyori_pro_t11.model3.json',
      );
      debugPrint('Live2D model loaded: $modelLoaded');
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
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (prev?.currentEmotion != next.currentEmotion && _live2dInitialized) {
        _playEmotionMotion(next.currentEmotion);
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_gradientTop, _gradientBottom, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 装饰元素
              ..._buildDecorations(),

              // Live2D 模型
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: isKeyboardVisible ? screenHeight * 0.35 : screenHeight * 0.5,
                child: _buildLive2DArea(chatState),
              ),

              // 聊天区域 - 与模型保持间距
              Positioned(
                top: isKeyboardVisible ? screenHeight * 0.38 : screenHeight * 0.53,
                left: 0,
                right: 0,
                bottom: keyboardHeight,
                child: _buildChatArea(chatState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDecorations() {
    return [
      // 左上角装饰
      Positioned(
        top: 100,
        left: -30,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _lightPink.withValues(alpha: 0.3),
          ),
        ),
      ),
      // 右上角装饰
      Positioned(
        top: 50,
        right: -20,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primaryPink.withValues(alpha: 0.15),
          ),
        ),
      ),
    ];
  }

  Widget _buildLive2DArea(ChatState chatState) {
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: Live2DView(
              controller: _live2dController,
              onHitAreaTapped: _onHitAreaTapped,
            ),
          ),
        ),

        // 顶部操作栏
        Positioned(
          top: 8,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _EmotionIndicator(emotion: chatState.currentEmotion),
              _ActionButton(
                icon: Icons.refresh_rounded,
                onTap: () => _showClearDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatArea(ChatState chatState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 拖动指示条
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _lightPink.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 消息列表
          Expanded(
            child: chatState.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_border_rounded,
                            size: 48, color: _lightPink.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          '和我聊聊天吧~',
                          style: TextStyle(
                            color: _primaryPink.withValues(alpha: 0.6),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          // 加载状态
          if (chatState.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primaryPink.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '思考中...',
                    style: TextStyle(color: _primaryPink.withValues(alpha: 0.6), fontSize: 13),
                  ),
                ],
              ),
            ),

          // 错误提示
          if (chatState.error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                chatState.error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),

          // 输入框
          ChatInput(onSend: (text) => ref.read(chatProvider.notifier).sendMessage(text)),
        ],
      ),
    );
  }

  void _playEmotionMotion(EmotionType emotion) {
    final mapping = EmotionMotionMapper.getMotionForEmotion(emotion);
    _live2dController.playMotion(
      mapping.group,
      index: mapping.index,
      priority: mapping.priority,
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('清除对话', style: TextStyle(color: Color(0xFF333333))),
        content: const Text('确定要清除所有对话记录吗？', style: TextStyle(color: Color(0xFF666666))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearMessages();
              Navigator.pop(ctx);
            },
            child: const Text('确定', style: TextStyle(color: _primaryPink)),
          ),
        ],
      ),
    );
  }
}

// 情绪指示器
class _EmotionIndicator extends StatelessWidget {
  final EmotionType emotion;
  const _EmotionIndicator({required this.emotion});

  static const _primaryPink = Color(0xFFFF85A2);
  // static const _lightPink = Color(0xFFFFB6C8);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emotion.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            emotion.label,
            style: TextStyle(
              color: _primaryPink.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// 操作按钮
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  static const _primaryPink = Color(0xFFFF85A2);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _primaryPink.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: _primaryPink, size: 20),
      ),
    );
  }
}

// 消息气泡
class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final EmotionType? emotion;

  const _MessageBubble({required this.text, required this.isUser, this.emotion});

  static const _primaryPink = Color(0xFFFF85A2);
  static const _lightPink = Color(0xFFFFE4EC);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFFFF85A2), Color(0xFFFF6B8A)],
                )
              : null,
          color: isUser ? null : _lightPink,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryPink.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF4A4A4A),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (!isUser && emotion != null) ...[
              const SizedBox(height: 6),
              Text(
                emotion!.emoji,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
