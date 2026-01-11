import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumi/core/config/app_settings.dart';
import 'package:lumi/core/theme/app_theme.dart';
import 'package:lumi/features/body/domain/emotion_motion_mapper.dart';
import 'package:lumi/features/body/presentation/controllers/live2d_controller.dart';
import 'package:lumi/features/body/presentation/providers/live2d_provider.dart';
import 'package:lumi/features/body/presentation/widgets/live2d_view.dart';
import 'package:lumi/features/chat/presentation/widgets/chat_input.dart';
import 'package:lumi/features/settings/presentation/pages/settings_page.dart';
import 'package:lumi/features/soul/domain/entities/emotion.dart';
import 'package:lumi/features/soul/presentation/providers/chat_provider.dart';

class LumiHomePage extends ConsumerStatefulWidget {
  const LumiHomePage({super.key});

  // 路由观察者（用于监听页面切换，暂停/恢复 Live2D）
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  ConsumerState<LumiHomePage> createState() => _LumiHomePageState();
}

class _LumiHomePageState extends ConsumerState<LumiHomePage> with RouteAware {
  late Live2DController _live2dController;
  bool _live2dInitialized = false;
  final ScrollController _scrollController = ScrollController();

  // 主题色

  // static const _gradientTop = Color(0xFFFFE4EC);
  // static const _primaryPink = Color(0xFFFF85A2);
  // static const _lightPink = Color(0xFFFFB6C8);

  @override
  void initState() {
    super.initState();
    _live2dController = ref.read(live2dControllerProvider);
    _initLive2D();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 订阅路由变化
    LumiHomePage.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    LumiHomePage.routeObserver.unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  // 当前页面被其他页面覆盖时调用（进入设置页）
  @override
  void didPushNext() {
    debugPrint('LumiHomePage: didPushNext - pausing Live2D');
    _live2dController.pause();
  }

  // 从其他页面返回到当前页面时调用（从设置页返回）
  @override
  void didPopNext() {
    debugPrint('LumiHomePage: didPopNext - resuming Live2D');
    _live2dController.resume();
  }

  Future<void> _initLive2D() async {
    // 等待设置加载完成
    final settings = await ref.read(appSettingsProvider.notifier).waitForLoad();
    final resolution = settings.renderQuality.resolution;

    final success = await _live2dController.initialize(
      width: resolution,
      height: resolution,
    );
    if (success) {
      await _live2dController.loadModel(
        'hiyori_pro_zh/runtime/hiyori_pro_t11.model3.json',
      );
      setState(() => _live2dInitialized = true);
    }
  }

  void _onHitAreaTapped(String hitArea) {
    debugPrint('Hit area tapped: $hitArea');
    switch (hitArea) {
      case 'Body':
        _live2dController.playMotion('Tap@Body');
        break;
      default:
        _live2dController.playMotion('Tap');
    }
  }

  void _playEmotionMotion(EmotionType emotion) {
    final mapping = EmotionMotionMapper.getMotionForEmotion(emotion);
    _live2dController.playMotion(
      mapping.group,
      index: mapping.index,
      priority: mapping.priority,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // 监听情感变化
    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (prev?.currentEmotion != next.currentEmotion && _live2dInitialized) {
        _playEmotionMotion(next.currentEmotion);
      }
      // 新消息时滚动到底部
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Layer 0: 背景渐变 + 装饰
          _buildBackground(),

          // Layer 1: Live2D 固定全屏
          _buildLive2DLayer(),

          // Layer 2: 顶部操作栏
          _buildTopBar(chatState),

          // Layer 3: 聊天界面 (带动画)
          _buildChatInterface(chatState, keyboardHeight),
        ],
      ),
    );
  }

  /// 背景渐变 + 装饰圆球
  Widget _buildBackground() {
    final lumiColors = context.lumiColors;
    final colorScheme = context.colorScheme;
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lumiColors.backgroundGradientTop,
              lumiColors.backgroundGradientMiddle,
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.secondary.withValues(alpha: 0.3),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Live2D 层 - 固定全屏，永不变化
  Widget _buildLive2DLayer() {
    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 200),
          child: Center(
            child: AspectRatio(
              aspectRatio: 1, // 保持 1:1 比例
              child: AnimatedOpacity(
                opacity: _live2dInitialized ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Live2DView(
                  controller: _live2dController,
                  onHitAreaTapped: _onHitAreaTapped,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 顶部操作栏
  Widget _buildTopBar(ChatState chatState) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _EmotionIndicator(emotion: chatState.currentEmotion),
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.settings_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.refresh_rounded,
                    onTap: () => _showClearDialog(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 聊天界面 - 带键盘动画
  Widget _buildChatInterface(ChatState chatState, double keyboardHeight) {
    final colorScheme = context.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;

    const minLive2DSpace = 280.0;
    const defaultChatHeight = 280.0;

    final availableHeight =
        screenHeight - safeTop - minLive2DSpace - keyboardHeight;
    final chatHeight = keyboardHeight > 0
        ? availableHeight.clamp(200.0, defaultChatHeight)
        : defaultChatHeight;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: chatHeight,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(child: _buildMessageList(chatState)),
              if (chatState.isLoading) _buildLoadingIndicator(),
              if (chatState.error != null) _buildErrorBanner(chatState.error!),
              ChatInput(
                onSend: (text) =>
                    ref.read(chatProvider.notifier).sendMessage(text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatState chatState) {
    final colorScheme = context.colorScheme;
    if (chatState.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 48,
              color: colorScheme.secondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              '和我聊聊天吧~',
              style: TextStyle(
                color: colorScheme.primary.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
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
    );
  }

  Widget _buildLoadingIndicator() {
    final colorScheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.secondary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '思考中...',
            style: TextStyle(
              color: colorScheme.primary.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        error,
        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('清除对话', style: TextStyle(color: Color(0xFF333333))),
        content: const Text(
          '确定要清除所有对话记录吗？',
          style: TextStyle(color: Color(0xFF666666)),
        ),
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
            child: Text(
              '确定',
              style: TextStyle(color: context.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ 小组件 ============

class _EmotionIndicator extends StatelessWidget {
  final EmotionType emotion;
  const _EmotionIndicator({required this.emotion});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.15),
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
              color: colorScheme.primary.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final EmotionType? emotion;

  const _MessageBubble({
    required this.text,
    required this.isUser,
    this.emotion,
  });

  @override
  Widget build(BuildContext context) {
    final lumiColors = context.lumiColors;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  colors: [
                    lumiColors.primaryGradientStart,
                    lumiColors.primaryGradientEnd,
                  ],
                )
              : null,
          color: isUser ? null : lumiColors.messageBubbleAI,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: lumiColors.shadowColor.withValues(alpha: 0.1),
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
                color: isUser ? Colors.white : lumiColors.textTertiary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (!isUser && emotion != null) ...[
              const SizedBox(height: 6),
              Text(emotion!.emoji, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}
