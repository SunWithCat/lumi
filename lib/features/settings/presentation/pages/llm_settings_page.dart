import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumi/core/config/app_settings.dart';
import 'package:lumi/core/theme/app_theme.dart';
import 'package:toastification/toastification.dart';

class LLMSettingsPage extends ConsumerStatefulWidget {
  const LLMSettingsPage({super.key});

  @override
  ConsumerState<LLMSettingsPage> createState() => _LLMSettingsPageState();
}

class _LLMSettingsPageState extends ConsumerState<LLMSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final settings = ref.watch(appSettingsProvider);
    final llm = settings.llmSettings;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('LLM 参数', style: TextStyle(color: Color(0xFF333333))),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(context),
          const SizedBox(height: 20),
          _buildSliderCard(
            context: context,
            title: '回复长度',
            subtitle: 'Max Tokens: ${llm.maxTokens}',
            description: '控制回复的最大长度，越大回复越详细',
            value: llm.maxTokens.toDouble(),
            min: 100,
            max: 4096,
            divisions: 19,
            onChanged: (v) => ref
                .read(appSettingsProvider.notifier)
                .setLLMMaxTokens(v.round()),
            valueLabel: _getMaxTokensLabel(llm.maxTokens),
          ),
          const SizedBox(height: 16),
          _buildSliderCard(
            context: context,
            title: '创意度',
            subtitle: 'Temperature: ${llm.temperature.toStringAsFixed(1)}',
            description: '越高回复越随机有创意，越低越稳定一致',
            value: llm.temperature,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            onChanged: (v) =>
                ref.read(appSettingsProvider.notifier).setLLMTemperature(v),
            valueLabel: _getTemperatureLabel(llm.temperature),
          ),
          const SizedBox(height: 16),
          _buildSliderCard(
            context: context,
            title: '采样范围',
            subtitle: 'Top P: ${llm.topP.toStringAsFixed(1)}',
            description: '控制词汇选择范围，通常保持 1.0 即可',
            value: llm.topP,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            onChanged: (v) =>
                ref.read(appSettingsProvider.notifier).setLLMTopP(v),
            valueLabel: _getTopPLabel(llm.topP),
          ),
          const SizedBox(height: 16),
          _buildSliderCard(
            context: context,
            title: '上下文长度',
            subtitle: '消息数: ${llm.maxContextMessages}',
            description: '保留的对话历史条数，越大记忆越长但消耗更多 Tokens',
            value: llm.maxContextMessages.toDouble(),
            min: 50,
            max: 1000,
            divisions: 19,
            onChanged: (v) =>
                ref.read(appSettingsProvider.notifier).setMaxContextMessages(v.round()),
            valueLabel: _getMaxContextMessagesLabel(llm.maxContextMessages),
          ),
          const SizedBox(height: 20),
          _buildPresetButtons(context),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '调整这些参数可以改变 AI 的回复风格和长度',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String valueLabel,
  }) {
    final colorScheme = context.colorScheme;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  valueLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.secondary.withValues(alpha: 0.3),
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快捷预设',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPresetButton(context, '简短', 200, 0.7, 1.0)),
            const SizedBox(width: 10),
            Expanded(child: _buildPresetButton(context, '标准', 500, 0.7, 1.0)),
            const SizedBox(width: 10),
            Expanded(child: _buildPresetButton(context, '详细', 1000, 0.8, 1.0)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildPresetButton(context, '稳定', 500, 0.3, 1.0)),
            const SizedBox(width: 10),
            Expanded(child: _buildPresetButton(context, '平衡', 500, 0.7, 1.0)),
            const SizedBox(width: 10),
            Expanded(child: _buildPresetButton(context, '创意', 500, 1.2, 1.0)),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetButton(
    BuildContext context,
    String label,
    int maxTokens,
    double temp,
    double topP,
  ) {
    final colorScheme = context.colorScheme;
    return GestureDetector(
      onTap: () {
        final notifier = ref.read(appSettingsProvider.notifier);
        notifier.updateLLMSettings(
          LLMSettings(maxTokens: maxTokens, temperature: temp, topP: topP),
        );
        toastification.dismissAll();
        toastification.show(
          context: context,
          title: Text('已应用「$label」预设'),
          type: ToastificationType.success,
          style: ToastificationStyle.flat,
          primaryColor: colorScheme.primary,
          icon: Icon(Icons.check_circle_rounded, color: colorScheme.primary),
          autoCloseDuration: const Duration(seconds: 2),
          alignment: Alignment.bottomCenter,
          showProgressBar: false,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.secondary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  String _getMaxTokensLabel(int value) {
    if (value <= 200) return '简短';
    if (value <= 500) return '标准';
    if (value <= 1000) return '详细';
    return '超长';
  }

  String _getTemperatureLabel(double value) {
    if (value <= 0.3) return '稳定';
    if (value <= 0.7) return '平衡';
    if (value <= 1.2) return '创意';
    return '随机';
  }

  String _getTopPLabel(double value) {
    if (value <= 0.5) return '精确';
    if (value <= 0.9) return '平衡';
    return '广泛';
  }

  String _getMaxContextMessagesLabel(int value) {
    if (value <= 100) return '较短';
    if (value <= 300) return '标准';
    if (value <= 500) return '较长';
    return '超长';
  }
}
