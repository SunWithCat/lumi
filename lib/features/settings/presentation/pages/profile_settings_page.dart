import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lumi/core/theme/app_theme.dart';
import 'package:lumi/features/auth/presentation/providers/auth_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toastification/toastification.dart';
import 'package:path/path.dart' as p;

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  final _imagePicker = ImagePicker();

  String _gender = '未设置';
  DateTime? _birthday;
  String? _avatarPath;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).currentUser;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _gender = user?.gender ?? '未设置';
    _birthday = user?.birthday;
    _avatarPath = user?.avatarPath;
    _usernameController.addListener(_markChanged);
    _bioController.addListener(_markChanged);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final user = ref.watch(authProvider.select((state) => state.currentUser));

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('我的档案')),
        body: const Center(child: Text('登录状态掉线了捏~(>_<)~，重新登录试试？')),
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasChanges) {
          _showDiscardDialog();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('我的档案', style: TextStyle(color: Color(0xFF333333))),
          leading: IconButton(
            onPressed: () {
              if (_hasChanges) {
                _showDiscardDialog();
              } else {
                context.pop();
              }
            },
            icon: Icon(Icons.arrow_back_ios, color: colorScheme.primary),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 10),
            _buildAvatarSection(colorScheme),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTextFieldInCard(
                    '冒险者代号',
                    _usernameController,
                    hint: '起个名字吧！✨',
                    maxLength: 20,
                  ),
                  const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Color(0xFFF5F5F5),
                  ),
                  _buildGenderSelectorRow(colorScheme),
                  const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Color(0xFFF5F5F5),
                  ),
                  _buildBirthdaySelectorInCard(colorScheme),
                  const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Color(0xFFF5F5F5),
                  ),
                  _buildTextFieldInCard(
                    '个性宣言',
                    _bioController,
                    hint: '介绍一下自己吧',
                    maxLines: 3,
                    maxLength: 120,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _hasChanges && !_isSaving ? _saveProfile : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '保存档案 ⚡',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(ColorScheme colorScheme) {
    final avatarFile = _avatarPath == null ? null : File(_avatarPath!);
    final hasAvatar = avatarFile != null && avatarFile.existsSync();
    final initial = _usernameController.text.trim().isEmpty
        ? 'L'
        : _usernameController.text.trim()[0];

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 头像外圈霓虹光晕
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
                width: 4,
              ),
            ),
            child: GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: hasAvatar ? FileImage(avatarFile) : null,
                child: hasAvatar
                    ? null
                    : Text(
                        initial,
                        style: TextStyle(
                          fontSize: 36,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (_avatarPath != null)
            Positioned(
              top: -4,
              right: -4,
              child: GestureDetector(
                onTap: _removeAvatar,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxHeight: 512,
      maxWidth: 512,
      imageQuality: 85,
    );
    if (picked == null) {
      return;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final avatarDir = Directory(p.join(appDir.path, 'avatars'));
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }

    final extension = p.extension(picked.path).isEmpty
        ? '.jpg'
        : p.extension(picked.path);
    final avatarFile = File(
      p.join(
        avatarDir.path,
        'user_avatar_${DateTime.now().millisecondsSinceEpoch}$extension',
      ),
    );
    await File(picked.path).copy(avatarFile.path);
    if (!mounted) {
      return;
    }
    setState(() {
      _avatarPath = avatarFile.path;
      _hasChanges = true;
    });
  }

  void _removeAvatar() {
    setState(() {
      _avatarPath = null;
      _hasChanges = true;
    });
  }

  Widget _buildTextFieldInCard(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 14,
              ),
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelectorRow(ColorScheme colorScheme) {
    final options = ['未设置', '男', '女', '秘密'];
    final optionIcons = {
      '未设置': '🛸 未设置',
      '男': '♂️ 男',
      '女': '♀️ 女',
      '秘密': '🤫 保密',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '性别',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: options.map((gender) {
              final isSelected = _gender == gender;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _gender = gender;
                    _hasChanges = true;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    optionIcons[gender]!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? colorScheme.primary
                          : const Color(0xFF555555),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdaySelectorInCard(ColorScheme colorScheme) {
    final text = _birthday == null ? '未设置' : _formatDate(_birthday!);

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _birthday ?? DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked == null) return;
        setState(() {
          _birthday = picked;
          _hasChanges = true;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '生日',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    color: _birthday == null
                        ? const Color(0xFFCCCCCC)
                        : const Color(0xFF333333),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (_birthday != null)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF999999),
                    ),
                    onPressed: () => setState(() {
                      _birthday = null;
                      _hasChanges = true;
                    }),
                  ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCCCCCC),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDiscardDialog() {
    final colorScheme = context.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('要放弃更改吗？(；′⌒`)'),
        content: const Text('Darling，你修改的档案内容还没保存哦，确定要丢弃这些修改吗？💦'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('我再改改！✨', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('任性离开 🚪'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final error = await ref
        .read(authProvider.notifier)
        .updateProfile(
          username: _usernameController.text,
          gender: _gender,
          birthday: _birthday,
          bio: _bioController.text,
          avatarPath: _avatarPath,
        );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      if (error == null) _hasChanges = false;
    });

    toastification.dismissAll();
    toastification.show(
      context: context,
      title: Text(error ?? '保存成功！🎉'),
      type: error == null
          ? ToastificationType.success
          : ToastificationType.error,
      autoCloseDuration: const Duration(seconds: 2),
      alignment: Alignment.bottomCenter,
      showProgressBar: false,
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
