import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumi/core/config/app_settings.dart';
import 'package:lumi/features/memory/presentation/pages/memory_management_page.dart';
import 'package:lumi/features/settings/presentation/pages/llm_settings_page.dart';
import 'package:lumi/features/soul/presentation/pages/persona_settings_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _primaryPink = Color(0xFFFF85A2);
  static const _lightPink = Color(0xFFFFE4EC);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('设置', style: TextStyle(color: Color(0xFF333333))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _primaryPink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('角色'),
          _buildSettingCard(
            icon: Icons.person_rounded,
            title: '人格设置',
            subtitle: '切换或自定义角色人格',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PersonaSettingsPage()),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('AI 模型'),
          _buildSettingCard(
            icon: Icons.psychology_rounded,
            title: 'LLM 参数',
            subtitle: '调整回复长度、创意度等',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LLMSettingsPage()),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('数据'),
          _buildSettingCard(
            icon: Icons.memory_rounded,
            title: '记忆管理',
            subtitle: '查看、删除或压缩 AI 的记忆',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MemoryManagementPage()),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('画质'),
          _buildQualitySelector(context, ref, settings.renderQuality),
          const SizedBox(height: 12),
          _buildQualityHint(),
        ],
      ),
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
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _lightPink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _primaryPink, size: 22),
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

  Widget _buildQualitySelector(BuildContext context, WidgetRef ref, RenderQuality current) {
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
                      color: isSelected ? _primaryPink : _lightPink,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getQualityIcon(quality),
                      color: isSelected ? Colors.white : _primaryPink,
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
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        Text(
                          quality.description,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: _primaryPink, size: 22)
                  else
                    Icon(Icons.circle_outlined, color: Colors.grey[300], size: 22),
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

  Widget _buildQualityHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lightPink.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _primaryPink, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '更改画质后需要重启应用才能生效',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _onQualityChanged(BuildContext context, WidgetRef ref, RenderQuality quality) {
    ref.read(appSettingsProvider.notifier).setRenderQuality(quality);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已切换为${quality.label}，重启后生效'),
        backgroundColor: _primaryPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
