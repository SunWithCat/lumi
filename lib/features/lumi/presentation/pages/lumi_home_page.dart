import 'dart:ui';

import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumi/core/config/app_settings.dart';
import 'package:lumi/core/router/app_router.dart';
import 'package:lumi/core/theme/app_theme.dart';
import 'package:lumi/features/body/domain/emotion_motion_mapper.dart';
import 'package:lumi/features/body/presentation/controllers/live2d_controller.dart';
import 'package:lumi/features/body/presentation/providers/live2d_provider.dart';
import 'package:lumi/features/body/presentation/widgets/live2d_view.dart';
import 'package:lumi/features/chat/presentation/widgets/chat_input.dart';
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
  int? _lastResolution;
  final ScrollController _scrollController = ScrollController();
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
    debugPrint('LumiHomePage: didPushNext - 暂停 Live2D');
    FocusManager.instance.primaryFocus?.unfocus();
    _live2dController.pause();
  }

  // 从其他页面返回到当前页面时调用（从设置页返回）
  @override
  void didPopNext() {
    debugPrint('LumiHomePage: didPopNext - 检查分辨率是否改变');
    final currentResolution = ref
        .read(appSettingsProvider)
        .renderQuality
        .resolution;

    if (_lastResolution != null && _lastResolution != currentResolution) {
      // 分辨率变了，需要重建渲染管线
      debugPrint('分辨率改变了: $_lastResolution → $currentResolution');
      _reinitWithNewResolution(currentResolution);
    } else {
      _live2dController.resume();
    }
  }

  /// 用新分辨率重建 Live2D
  Future<void> _reinitWithNewResolution(int resolution) async {
    setState(() => _live2dInitialized = false);

    final success = await _live2dController.reinitialize(
      width: resolution,
      height: resolution,
    );

    if (success) {
      _lastResolution = resolution;
      setState(() => _live2dInitialized = true);
    }
  }

  Future<void> _initLive2D() async {
    // 如果是重登，跳过等待设置加载完成
    if (_live2dController.isInitialized && _live2dController.isModelLoaded) {
      _lastResolution = ref.read(appSettingsProvider).renderQuality.resolution;
      await _live2dController.resume();
      setState(() => _live2dInitialized = true);
      return;
    }
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
      _lastResolution = resolution;
      await _live2dController.resume(); // 解除可能残留的暂停状态
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

  /// 仅在用户翻了历史消息时，平滑滚回底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      // reverse 模式下 offset=0 就是最新消息，大于0说明翻了历史
      if (_scrollController.offset > 1) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 监听情感变化
    ref.listen<ChatState>(chatProvider, (prev, next) {
      if (prev?.currentEmotion != next.currentEmotion && _live2dInitialized) {
        _playEmotionMotion(next.currentEmotion);
      }
      // 新消息时，如果用户翻了历史就滚回底部
      // 入场动画由 _MessageBubble 自身处理
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
      // Key未配置时，弹窗引导
      if (next.error == 'API_KEY_NOT_CONFIGURED' &&
          prev?.error != 'API_KEY_NOT_CONFIGURED') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('还没配置 API Key哦~'),
              content: const Text(
                '需要先在设置页面填写 API Key，快去配置一下吧，不然我没法陪你聊天呢~(≧ω≦)',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('再想想'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.settingsApi); // 跳转到设置
                  },
                  child: const Text('去配置'),
                ),
              ],
            ),
          );
        });
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

          // Layer 2: 顶部操作栏 - 独立 Widget，自己管理数据订阅
          const _TopBar(),

          // Layer 3: 聊天界面
          _ChatPanel(scrollController: _scrollController),
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
        child: RepaintBoundary(
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
      ),
    );
  }
}

/// 避免触发父级 LumiHomePage 重建
class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);

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
                    onTap: () => context.push(AppRoutes.settings),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.refresh_rounded,
                    onTap: () => _showClearDialog(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
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

class _ChatPanel extends ConsumerWidget {
  final ScrollController scrollController;

  static const _defaultChatHeight = 280.0;

  const _ChatPanel({required this.scrollController});

  Widget _buildMessageList(
    BuildContext context,
    ChatState chatState,
    double maxBubbleWidth,
  ) {
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
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final msg = chatState.messages[chatState.messages.length - 1 - index];
        return RepaintBoundary(
          child: _MessageBubble(
            key: ValueKey(msg.id),
            text: msg.content,
            isUser: msg.isUser,
            emotion: msg.emotion,
            timestamp: msg.timestamp,
            maxWidth: maxBubbleWidth,
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator(BuildContext context) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // MediaQuery 只在这里读取，只有这个 Widget 会被键盘动画触发重建
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final colorScheme = context.colorScheme;
    final chatState = ref.watch(chatProvider);
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.75;

    return Positioned(
      left: 0,
      right: 0,
      bottom: keyboardHeight,
      height: _defaultChatHeight,
      child: RepaintBoundary(
        child: Material(
          color: Colors.transparent,
          elevation: 8,
          shadowColor: colorScheme.primary.withValues(alpha: 0.3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                color: Colors.white.withValues(alpha: 0.7),
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
                    Expanded(
                      child: _buildMessageList(
                        context,
                        chatState,
                        maxBubbleWidth,
                      ),
                    ),
                    if (chatState.isLoading) _buildLoadingIndicator(context),
                    if (chatState.error != null)
                      _buildErrorBanner(chatState.error!),
                    ChatInput(
                      onSend: (text) =>
                          ref.read(chatProvider.notifier).sendMessage(text),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 消息气泡 - 使用 flutter_animate 实现入场动画
class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final EmotionType? emotion;
  final DateTime timestamp;
  final double maxWidth;

  const _MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.emotion,
    required this.timestamp,
    required this.maxWidth,
  });

  /// 只有2秒内的新消息才播放入场动画
  bool get _isNew => DateTime.now().difference(timestamp).inSeconds < 2;

  @override
  Widget build(BuildContext context) {
    final lumiColors = context.lumiColors;
    final bubble = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: maxWidth),
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
          Text(
            _formatTime(timestamp),
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );

    // 新消息：播放淡入 + 缩放 + 方向性滑入动画；历史消息：直接显示
    if (_isNew) {
      return bubble
          .animate()
          .fadeIn(
            delay: 25.ms, // 等待 Layout 稳定，防止第一帧闪现
            duration: 300.ms,
          )
          .scale(
            begin: const Offset(0.8, 0.8),
            duration: 400.ms,
            curve: Curves.easeOutBack, // 带一点 Q 弹的感觉
          )
          .slide(
            // 用户消息从右下飞入，AI 消息从左下飞入
            begin: Offset(isUser ? 0.2 : -0.2, 0.2),
            end: Offset.zero,
            duration: 450.ms,
            curve: Curves.easeOutCubic,
          );
    }
    return bubble;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(time.year, time.month, time.day);
    final difference = today.difference(messageDay).inDays;
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    if (difference == 0) {
      return timeStr;
    } else if (difference == 1) {
      return '昨天 $timeStr';
    } else if (time.year == now.year) {
      final month = time.month.toString().padLeft(2, '0');
      final day = time.day.toString().padLeft(2, '0');
      return '$month-$day $timeStr';
    } else {
      final year = time.year;
      final month = time.month.toString().padLeft(2, '0');
      final day = time.day.toString().padLeft(2, '0');
      return '$year-$month-$day $timeStr';
    }
  }
}
