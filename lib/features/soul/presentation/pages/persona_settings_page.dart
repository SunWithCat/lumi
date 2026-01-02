import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumi/features/soul/domain/entities/persona_config.dart';
import 'package:lumi/features/soul/presentation/providers/persona_provider.dart';

class PersonaSettingsPage extends ConsumerStatefulWidget {
  const PersonaSettingsPage({super.key});

  @override
  ConsumerState<PersonaSettingsPage> createState() => _PersonaSettingsPageState();
}

class _PersonaSettingsPageState extends ConsumerState<PersonaSettingsPage> {
  static const _primaryPink = Color(0xFFFF85A2);
  static const _lightPink = Color(0xFFFFE4EC);

  @override
  Widget build(BuildContext context) {
    final personaAsync = ref.watch(currentPersonaProvider);
    final allPersonasAsync = ref.watch(allPersonasProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('人格设置', style: TextStyle(color: Color(0xFF333333))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _primaryPink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: personaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _primaryPink)),
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
              loading: () => const Center(child: CircularProgressIndicator(color: _primaryPink)),
              error: (e, _) => Text('加载失败: $e'),
              data: (personas) => Column(
                children: personas.map((p) => _buildPersonaCard(p, currentPersona)).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // 自定义按钮
            _buildCustomizeButton(currentPersona),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPersonaCard(PersonaConfig persona) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF85A2), Color(0xFFFF6B8A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withValues(alpha:0.3),
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
                  color: Colors.white.withValues(alpha:0.2),
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
                        color: Colors.white.withValues(alpha:0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.2),
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
              color: Colors.white.withValues(alpha:0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: persona.traits.map((t) => _buildTraitChip(t, true)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaCard(PersonaConfig persona, PersonaConfig current) {
    final isSelected = persona.id == current.id;
    final personaId = int.tryParse(persona.id) ?? 0;
    final isPreset = personaId <= 3;  // ID 1-3 是预设人格

    return GestureDetector(
      onTap: isSelected ? null : () => _selectPersona(persona),
      onLongPress: () => _showDeleteDialog(persona, isSelected, isPreset),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: _primaryPink, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
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
                color: isSelected ? _primaryPink : _lightPink,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  persona.name[0],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : _primaryPink,
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _lightPink,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '自定义',
                            style: TextStyle(fontSize: 10, color: _primaryPink),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    persona.bio,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: _primaryPink, size: 24)
            else
              Icon(Icons.circle_outlined, color: Colors.grey[300], size: 24),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(PersonaConfig persona, bool isSelected, bool isPreset) {
    final personaId = int.tryParse(persona.id);
    if (personaId == null) return;

    if (isPreset) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('预设人格无法删除'),
          backgroundColor: Colors.grey[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (isSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请先切换到其他人格再删除'),
          backgroundColor: Colors.grey[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('删除人格'),
        content: Text('确定要删除「${persona.name}」吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              ref.read(currentPersonaProvider.notifier).deletePersona(personaId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已删除「${persona.name}」'),
                  backgroundColor: _primaryPink,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _selectPersona(PersonaConfig persona) {
    final personaId = int.tryParse(persona.id);
    if (personaId != null) {
      ref.read(currentPersonaProvider.notifier).setPersonaById(personaId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已切换为 ${persona.name}'),
          backgroundColor: _primaryPink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildTraitChip(String trait, bool isWhite) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isWhite ? Colors.white.withValues(alpha:0.2) : _lightPink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        trait,
        style: TextStyle(
          fontSize: 12,
          color: isWhite ? Colors.white : _primaryPink,
        ),
      ),
    );
  }

  Widget _buildCustomizeButton(PersonaConfig current) {
    return GestureDetector(
      onTap: () => _showCustomizeDialog(current),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primaryPink.withValues(alpha:0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_rounded, color: _primaryPink, size: 20),
            const SizedBox(width: 8),
            Text(
              '自定义人格',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _primaryPink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomizeDialog(PersonaConfig current) {
    final nameController = TextEditingController(text: '');
    final bioController = TextEditingController(text: '');
    final userTitleController = TextEditingController(text: '主人');
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      _buildTextField('名字', nameController, hint: '给你的角色起个名字'),
                      const SizedBox(height: 16),
                      _buildTextField('简介', bioController, maxLines: 3, hint: '描述角色的性格和背景'),
                      const SizedBox(height: 16),
                      _buildTextField('称呼用户为', userTitleController, hint: '例如：主人、哥哥、你'),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[400], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            error,
                            style: TextStyle(color: Colors.red[700], fontSize: 13),
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
                      final userTitle = userTitleController.text.trim();
                      
                      if (name.isEmpty) {
                        errorNotifier.value = '请输入角色名字';
                        return;
                      }
                      
                      errorNotifier.value = null;
                      ref.read(currentPersonaProvider.notifier).createCustomPersona(
                        name: name,
                        bio: bio.isNotEmpty ? bio : '一个可爱的AI伙伴',
                        userTitle: userTitle.isNotEmpty ? userTitle : '主人',
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('已创建并切换到 $name'),
                          backgroundColor: _primaryPink,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryPink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('创建并使用', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, String? hint}) {
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
            fillColor: _lightPink.withValues(alpha:0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ),
      ],
    );
  }
}
