import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumi/core/config/app_settings.dart';
import 'package:lumi/core/theme/app_theme.dart';
import 'package:toastification/toastification.dart';

class ApiSettingsPage extends ConsumerStatefulWidget {
  const ApiSettingsPage({super.key});

  @override
  ConsumerState<ApiSettingsPage> createState() => _ApiSettingsPageState();
}

class _ApiSettingsPageState extends ConsumerState<ApiSettingsPage> {
  late TextEditingController _baseUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  bool _obscureApiKey = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider).apiSettings;
    _baseUrlController = TextEditingController(text: settings.baseUrl);
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _modelController = TextEditingController(text: settings.model);

    // 监听输入变化
    _baseUrlController.addListener(_onTextChanged);
    _apiKeyController.addListener(_onTextChanged);
    _modelController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _baseUrlController.removeListener(_onTextChanged);
    _apiKeyController.removeListener(_onTextChanged);
    _modelController.removeListener(_onTextChanged);
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
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
          title: const Text(
            'API 设置',
            style: TextStyle(color: Color(0xFF333333)),
          ),
          leading: IconButton(
            onPressed: () {
              if (_hasChanges) {
                _showDiscardDialog();
              } else {
                Navigator.pop(context);
              }
            },
            icon: Icon(Icons.arrow_back_ios, color: colorScheme.primary),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTextField(
                label: 'API Base URL',
                hint: 'https://api.deepseek.com/v1',
                controller: _baseUrlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                helperText: '支持 OpenAI 兼容格式的接口地址',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'API Key',
                hint: '输入你的 API Key',
                controller: _apiKeyController,
                obscureText: _obscureApiKey,
                textInputAction: TextInputAction.next,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[400],
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: '模型 ID',
                hint: 'deepseek-chat',
                controller: _modelController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveSettings(),
                helperText: '例如: deepseek-v3.2, glm-4.7',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '保存设置',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiscardDialog() {
    final colorScheme = context.colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('放弃更改？'),
        content: const Text('你有未保存的更改，确定要放弃吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('继续编辑', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('放弃', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    final colorScheme = context.colorScheme;
    final baseUrl = _baseUrlController.text.trim();
    final model = _modelController.text.trim();

    // 校验 URL 格式
    if (baseUrl.isNotEmpty &&
        !baseUrl.startsWith('http://') &&
        !baseUrl.startsWith('https://')) {
      toastification.dismissAll();
      toastification.show(
        context: context,
        title: const Text('URL 格式错误，需要以 http:// 或 https:// 开头'),
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        primaryColor: Colors.red[400],
        icon: Icon(Icons.error_outline, color: Colors.red[400]),
        autoCloseDuration: const Duration(seconds: 2),
        alignment: Alignment.bottomCenter,
        showProgressBar: false,
      );

      return;
    }

    // 校验 Model 不为空（如果 API Key 不为空的话）
    if (_apiKeyController.text.trim().isNotEmpty && model.isEmpty) {
      toastification.dismissAll();
      toastification.show(
        context: context,
        title: const Text('请输入模型 ID'),
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        primaryColor: Colors.red[400],
        icon: Icon(Icons.error_outline, color: Colors.red[400]),
        autoCloseDuration: const Duration(seconds: 2),
        alignment: Alignment.bottomCenter,
        showProgressBar: false,
      );
      return;
    }

    final newSettings = ApiSettings(
      baseUrl: baseUrl.isEmpty ? 'https://api.deepseek.com/v1' : baseUrl,
      apiKey: _apiKeyController.text.trim(),
      model: model.isEmpty ? 'deepseek-chat' : model,
    );
    ref.read(appSettingsProvider.notifier).updateApiSettings(newSettings);

    // 取消焦点
    FocusScope.of(context).unfocus();

    toastification.dismissAll();
    toastification.show(
      context: context,
      title: const Text('设置已保存'),
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      primaryColor: colorScheme.primary,
      icon: Icon(Icons.check_circle_rounded, color: colorScheme.primary),
      autoCloseDuration: const Duration(seconds: 2),
      alignment: Alignment.bottomCenter,
      showProgressBar: false,
    );

    // 返回上一页
    Navigator.pop(context);
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    String? helperText,
  }) {
    final colorScheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ],
    );
  }
}
