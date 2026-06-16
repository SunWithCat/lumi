import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumi/core/theme/app_theme.dart';
import 'package:lumi/features/soul/domain/entities/persona_config.dart';
import 'package:lumi/features/soul/presentation/providers/persona_provider.dart';
import 'package:toastification/toastification.dart';

class PersonaSettingsPage extends ConsumerStatefulWidget {
  const PersonaSettingsPage({super.key});

  @override
  ConsumerState<PersonaSettingsPage> createState() =>
      _PersonaSettingsPageState();
}

class _PersonaSettingsPageState extends ConsumerState<PersonaSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final personaAsync = ref.watch(currentPersonaProvider);
    final allPersonasAsync = ref.watch(allPersonasProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('人格设置', style: TextStyle(color: Color(0xFF333333))),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: personaAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (currentPersona) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 当前人格卡片
            _buildCurrentPersonaCard(currentPersona),
            const SizedBox(height: 24),

            // 人格列表（从数据库读取）
            const Text(
              '可用人格',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            allPersonasAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
              error: (e, _) => Text('加载失败: $e'),
              data: (personas) => Column(
                children: personas
                    .map((p) => _buildPersonaCard(context, p, currentPersona))
                    .toList(),
              ),
            ),

            const SizedBox(height: 24),

            // 自定义按钮
            _buildCustomizeButton(context, currentPersona),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPersonaCard(PersonaConfig persona) {
    final lumiColors = context.lumiColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            lumiColors.primaryGradientStart,
            lumiColors.primaryGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: lumiColors.shadowColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    persona.name[0],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      persona.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      persona.age,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '当前',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            persona.bio,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: persona.traits
                .map((t) => _buildTraitChip(context, t, true))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaCard(
    BuildContext context,
    PersonaConfig persona,
    PersonaConfig current,
  ) {
    final colorScheme = context.colorScheme;
    final isSelected = persona.id == current.id;
    final personaId = int.tryParse(persona.id) ?? 0;
    final isPreset = personaId <= 4; // ID 1-4 是预设人格

    return GestureDetector(
      onTap: isSelected ? null : () => _selectPersona(context, persona),
      onLongPress: () =>
          _showDeleteDialog(context, persona, isSelected, isPreset),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.secondary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  persona.name[0],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        persona.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isPreset)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '自定义',
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    persona.bio,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary, size: 24)
            else
              Icon(Icons.circle_outlined, color: Colors.grey[300], size: 24),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    PersonaConfig persona,
    bool isSelected,
    bool isPreset,
  ) {
    final colorScheme = context.colorScheme;
    final personaId = int.tryParse(persona.id);
    if (personaId == null) return;

    if (isPreset) {
      toastification.dismissAll();
      toastification.show(
        context: context,
        title: const Text('预设人格无法删除'),
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        primaryColor: Colors.grey[600],
        icon: Icon(Icons.error_outline, color: Colors.grey[600]),
        autoCloseDuration: const Duration(seconds: 2),
        alignment: Alignment.bottomCenter,
        showProgressBar: false,
      );
      return;
    }

    if (isSelected) {
      toastification.dismissAll();
      toastification.show(
        context: context,
        title: const Text('请先切换到其他人格再删除'),
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        primaryColor: Colors.grey[600],
        icon: Icon(Icons.error_outline, color: Colors.grey[600]),
        autoCloseDuration: const Duration(seconds: 2),
        alignment: Alignment.bottomCenter,
        showProgressBar: false,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_remove_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '删除人格',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        content: Text(
          '确定要删除「${persona.name}」吗？此操作无法撤销。',
          style: const TextStyle(color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(personaProvider.notifier).deletePersona(personaId);
              Navigator.pop(ctx);
              toastification.dismissAll();
              toastification.show(
                context: context,
                title: Text('已删除「${persona.name}」'),
                type: ToastificationType.success,
                style: ToastificationStyle.flat,
                primaryColor: colorScheme.primary,
                icon: Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                ),
                autoCloseDuration: const Duration(seconds: 2),
                alignment: Alignment.bottomCenter,
                showProgressBar: false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _selectPersona(BuildContext context, PersonaConfig persona) {
    final colorScheme = context.colorScheme;
    final personaId = int.tryParse(persona.id);
    if (personaId != null) {
      ref.read(personaProvider.notifier).setPersonaById(personaId);
      toastification.dismissAll();
      toastification.show(
        context: context,
        title: Text('已切换为 ${persona.name}'),
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

  Widget _buildTraitChip(BuildContext context, String trait, bool isWhite) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isWhite
            ? Colors.white.withValues(alpha: 0.2)
            : colorScheme.secondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        trait,
        style: TextStyle(
          fontSize: 12,
          color: isWhite ? Colors.white : colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCustomizeButton(BuildContext context, PersonaConfig current) {
    final colorScheme = context.colorScheme;
    return GestureDetector(
      onTap: () => _showCustomizeDialog(context, current),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_rounded, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              '自定义人格',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomizeDialog(BuildContext context, PersonaConfig current) {
    final colorScheme = context.colorScheme;
    final nameController = TextEditingController(text: '');
    final bioController = TextEditingController(text: '');
    final promptController = TextEditingController(text: '');
    final errorNotifier = ValueNotifier<String?>(null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 固定的标题栏
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '创建自定义人格',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '创建一个全新的人格，不会修改现有预设',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 可滚动的内容区域
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        context,
                        '名字',
                        nameController,
                        hint: '给你的角色起个名字',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        context,
                        '一句话简介 (选填)',
                        bioController,
                        maxLines: 2,
                        hint: '用于卡片展示（例如：一个高冷的御姐）',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        context,
                        '完整高阶提示词 (必填)',
                        promptController,
                        maxLines: 8,
                        hint: '在此赋予你的角色独一无二的灵魂吧 ✨ 填入你的专属人格提示词... ',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              // 错误提示（在按钮上方）
              ValueListenableBuilder<String?>(
                valueListenable: errorNotifier,
                builder: (context, error, _) {
                  if (error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[400],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            error,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // 固定的底部按钮
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final bio = bioController.text.trim();
                      final promptText = promptController.text.trim();

                      if (name.isEmpty) {
                        errorNotifier.value = '请输入角色名字';
                        return;
                      }

                      if (promptText.isEmpty) {
                        errorNotifier.value = '提示词不能为空哦！';
                        return;
                      }

                      errorNotifier.value = null;
                      ref
                          .read(personaProvider.notifier)
                          .createCustomPersona(
                            name: name,
                            bio: bio.isNotEmpty ? bio : '自定义专属人格',
                            customSystemPrompt: promptText,
                          );
                      Navigator.pop(ctx);
                      toastification.dismissAll();
                      toastification.show(
                        context: context,
                        title: Text('已创建并切换到 $name'),
                        type: ToastificationType.success,
                        style: ToastificationStyle.flat,
                        primaryColor: colorScheme.primary,
                        icon: Icon(
                          Icons.check_circle_rounded,
                          color: colorScheme.primary,
                        ),
                        autoCloseDuration: const Duration(seconds: 2),
                        alignment: Alignment.bottomCenter,
                        showProgressBar: false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '创建并使用',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
  }) {
    final colorScheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.secondary.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),
      ],
    );
  }
}
