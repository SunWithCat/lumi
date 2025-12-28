import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waifu/features/soul/domain/entities/persona_config.dart';
import 'package:waifu/features/soul/presentation/providers/persona_provider.dart';

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

            // 预设人格
            const Text(
              '预设人格',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            ...PersonaConfig.presets.map((p) => _buildPresetCard(p, currentPersona)),

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

  Widget _buildPresetCard(PersonaConfig preset, PersonaConfig current) {
    final isSelected = preset.id == current.id;

    return GestureDetector(
      onTap: isSelected ? null : () => _selectPreset(preset),
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
                color: _lightPink,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  preset.name[0],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryPink,
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
                        preset.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        preset.age,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset.bio,
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

  void _selectPreset(PersonaConfig preset) {
    ref.read(currentPersonaProvider.notifier).setPersona(preset);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已切换为 ${preset.name}'),
        backgroundColor: _primaryPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showCustomizeDialog(PersonaConfig current) {
    final nameController = TextEditingController(text: current.name);
    final bioController = TextEditingController(text: current.bio);
    final userTitleController = TextEditingController(text: current.userTitle);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '自定义人格',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField('名字', nameController),
              const SizedBox(height: 16),
              _buildTextField('简介', bioController, maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField('称呼用户为', userTitleController),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(currentPersonaProvider.notifier).updatePersona(
                      name: nameController.text,
                      bio: bioController.text,
                      userTitle: userTitleController.text,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('人格已更新'),
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
                  child: const Text('保存', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
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
          ),
        ),
      ],
    );
  }
}
