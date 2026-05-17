import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumi/core/config/app_settings.dart';
import 'package:lumi/core/router/app_router.dart';
import 'package:lumi/core/theme/app_theme.dart';
import 'package:lumi/core/utils/logger.dart';
import 'package:lumi/core/theme/theme_provider.dart';
import 'package:lumi/core/utils/url_launcher_utils.dart';
import 'package:lumi/features/auth/presentation/providers/auth_provider.dart';
import 'package:toastification/toastification.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  // static const _primaryPink = Color(0xFFFF85A2);
  // static const _lightPink = Color(0xFFFFE4EC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('设置', style: TextStyle(color: Color(0xFF333333))),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('角色'),
          _buildSettingCard(
            context: context,
            icon: Icons.person_rounded,
            title: '人格设置',
            subtitle: '切换或自定义角色人格',
            onTap: () => context.push(AppRoutes.settingsPersona),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('AI 模型'),
          _buildSettingCard(
            context: context,
            icon: Icons.psychology_rounded,
            title: 'LLM 参数',
            subtitle: '调整回复长度、创意度等',
            onTap: () => context.push(AppRoutes.settingsLlm),
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            context: context,
            icon: Icons.api_rounded,
            title: 'API 设置',
            subtitle: settings.apiSettings.isConfigured
                ? '已配置 (${settings.apiSettings.model})'
                : '配置 OpenAI 兼容接口',
            onTap: () => context.push(AppRoutes.settingsApi),
          ),
          const SizedBox(height: 12),
          _buildSearchToggle(context, ref, settings),
          const SizedBox(height: 24),
          _buildSectionTitle('数据'),
          _buildSettingCard(
            context: context,
            icon: Icons.memory_rounded,
            title: '记忆管理',
            subtitle: '查看、删除或压缩 AI 的记忆',
            onTap: () => context.push(AppRoutes.settingsMemory),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('画质'),
          _buildQualitySelector(context, ref, settings.renderQuality),
          const SizedBox(height: 12),
          _buildQualityHint(context),
          const SizedBox(height: 24),
          _buildSectionTitle('主题'),
          _buildThemeSelector(context, ref),
          const SizedBox(height: 24),
          _buildSectionTitle('关于'),
          _buildSettingCard(
            context: context,
            iconWidget: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.colorScheme.secondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: FaIcon(
                  FontAwesomeIcons.github,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
            title: 'GitHub 开源仓库',
            subtitle: '查看源码或反馈问题',
            onTap: () => UrlLauncherUtils.launchWebUrl(
              "https://github.com/SunWithCat/lumi",
            ),
          ),
          const SizedBox(height: 32),
          // 退出登录按钮
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _handleLogout(context, ref),
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: const Text(
                '退出登录',
                style: TextStyle(color: Colors.redAccent),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '退出登录',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              content: isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text('正在退出登录...',
                            style: TextStyle(color: Color(0xFF666666))),
                      ],
                    )
                  : const Text('确定要退出登录吗？',
                      style: TextStyle(color: Color(0xFF666666))),
              actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
              actions: isLoading
                  ? null
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('取消',
                            style: TextStyle(color: Colors.grey[600])),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() => isLoading = true);
                          await ref.read(authProvider.notifier).logout();
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!context.mounted) return;
                          context.go(AppRoutes.login);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('退出'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required BuildContext context,
    IconData? icon,
    Widget? iconWidget,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = context.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            iconWidget ??
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 22),
                ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchToggle(
    BuildContext context,
    WidgetRef ref,
    AppSettingsState settings,
  ) {
    final colorScheme = context.colorScheme;
    final hasEnable = settings.llmSettings.enableSearch;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.language_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '联网搜索',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '部分模型可用',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: hasEnable,
              activeColor: colorScheme.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (v) {
                ref.read(appSettingsProvider.notifier).setEnableSearch(v);
                AppLogger.d(v ? '开启联网' : '关闭联网');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualitySelector(
    BuildContext context,
    WidgetRef ref,
    RenderQuality current,
  ) {
    final colorScheme = context.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: RenderQuality.values.map((quality) {
          final isSelected = quality == current;
          return GestureDetector(
            onTap: () => _onQualityChanged(context, ref, quality),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: quality != RenderQuality.values.last
                    ? Border(bottom: BorderSide(color: Colors.grey.shade100))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.secondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getQualityIcon(quality),
                      color: isSelected ? Colors.white : colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quality.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        Text(
                          quality.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 22,
                    )
                  else
                    Icon(
                      Icons.circle_outlined,
                      color: Colors.grey[300],
                      size: 22,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getQualityIcon(RenderQuality quality) {
    switch (quality) {
      case RenderQuality.low:
        return Icons.battery_saver_rounded;
      case RenderQuality.medium:
        return Icons.balance_rounded;
      case RenderQuality.high:
        return Icons.hd_rounded;
    }
  }

  Widget _buildQualityHint(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: colorScheme.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '高画质更清晰但更耗电，返回后自动生效',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ThemeOptionCard(
              themeName: '浪漫粉',
              icon: Icons.favorite_rounded,
              gradientColors: const [Color(0xFFFF85A2), Color(0xFFFF6B8A)],
              isSelected: currentTheme == AppThemeMode.romantic,
              onTap: () => ref
                  .read(themeProvider.notifier)
                  .setTheme(AppThemeMode.romantic),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ThemeOptionCard(
              themeName: '海洋蓝',
              icon: Icons.water_drop_rounded,
              gradientColors: const [Color(0xFF64B5F6), Color(0xFF42A5F5)],
              isSelected: currentTheme == AppThemeMode.ocean,
              onTap: () =>
                  ref.read(themeProvider.notifier).setTheme(AppThemeMode.ocean),
            ),
          ),
        ],
      ),
    );
  }

  void _onQualityChanged(
    BuildContext context,
    WidgetRef ref,
    RenderQuality quality,
  ) {
    final colorScheme = context.colorScheme;
    ref.read(appSettingsProvider.notifier).setRenderQuality(quality);
    toastification.dismissAll();
    toastification.show(
      context: context,
      title: Text('分辨率已切换为${quality.label}'),
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      primaryColor: colorScheme.primary,
      icon: Icon(Icons.check_circle_rounded, color: colorScheme.primary),
      autoCloseDuration: const Duration(seconds: 2),
      alignment: Alignment.bottomCenter,
      showProgressBar: false,
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final String themeName;
  final IconData icon;
  final List<Color> gradientColors;
  final bool isSelected;
  final VoidCallback onTap;
  const _ThemeOptionCard({
    required this.themeName,
    required this.icon,
    required this.gradientColors,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                )
              : null,
          color: isSelected ? null : gradientColors[0].withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : gradientColors[0].withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : gradientColors[0].withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : gradientColors[0],
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              themeName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
