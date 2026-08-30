import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumi/core/config/app_settings.dart';
import 'package:lumi/core/theme/app_theme.dart';
import 'package:lumi/features/soul/data/llm_client.dart';
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

  bool _isLoadingModels = false;
  List<String> _cachedModels = [];

  Future<void> _fetchAndSelectModel() async {
    final baseUrl = _baseUrlController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (baseUrl.isEmpty) {
      _showToast('请输入 API Base URL', isError: true);
      return;
    }
    // 如果已经拉取过，直接弹抽屉（避免重复请求）
    if (_cachedModels.isNotEmpty) {
      _showModelPickerBottomSheet(_cachedModels);
      return;
    }
    setState(() => _isLoadingModels = true);
    FocusScope.of(context).unfocus();
    try {
      final models = await LLMClient.fetchModels(
        baseUrl: baseUrl,
        apiKey: apiKey,
      );
      if (!mounted) return;
      if (models.isEmpty) {
        _showToast('未找到可用模型列表，请确认地址与权限', isError: true);
        return;
      }
      setState(() => _cachedModels = models);
      _showModelPickerBottomSheet(models);
    } catch (e) {
      if (!mounted) return;
      _showToast(e.toString().replaceAll('LLMException: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoadingModels = false);
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    final colorScheme = context.colorScheme;
    toastification.dismissAll();
    toastification.show(
      context: context,
      title: Text(message),
      type: isError ? ToastificationType.error : ToastificationType.success,
      style: ToastificationStyle.flat,
      primaryColor: isError ? Colors.red[400] : colorScheme.primary,
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_rounded,
        color: isError ? Colors.red[400] : colorScheme.primary,
      ),
      autoCloseDuration: const Duration(seconds: 2),
      alignment: Alignment.bottomCenter,
      showProgressBar: false,
    );
  }

  void _showModelPickerBottomSheet(List<String> models) {
    final colorScheme = context.colorScheme;
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredModels = models
                .where(
                  (m) => m.toLowerCase().contains(searchQuery.toLowerCase()),
                )
                .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // 顶部拖拽条
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // 标题与刷新按钮
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '选择模型 (${filteredModels.length})',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            tooltip: '重新拉取',
                            onPressed: () {
                              Navigator.pop(ctx);
                              _cachedModels.clear();
                              _fetchAndSelectModel();
                            },
                          ),
                        ],
                      ),
                    ),
                    // 搜索框
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '搜索模型名称...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          setModalState(() => searchQuery = val);
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    // 模型列表
                    Expanded(
                      child: filteredModels.isEmpty
                          ? Center(
                              child: Text(
                                '未找到匹配的模型',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: filteredModels.length,
                              itemBuilder: (context, index) {
                                final model = filteredModels[index];
                                final isSelected =
                                    _modelController.text.trim() == model;

                                return ListTile(
                                  title: Text(
                                    model,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? colorScheme.primary
                                          : const Color(0xFF333333),
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          color: colorScheme.primary,
                                          size: 20,
                                        )
                                      : null,
                                  onTap: () {
                                    _modelController.text = model;
                                    _onTextChanged();
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider).apiSettings;
    _baseUrlController = TextEditingController(text: settings.baseUrl);
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _modelController = TextEditingController(text: settings.model);

    // 监听输入变化
    _baseUrlController.addListener(() {
      _cachedModels.clear();
      _onTextChanged();
    });
    _apiKeyController.addListener(() {
      _cachedModels.clear();
      _onTextChanged();
    });
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
                context.pop();
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
                hint: 'deepseek-v4-flash',
                controller: _modelController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveSettings(),
                helperText: '可手动输入，或点击右侧按钮在线获取模型列表',
                suffixIcon: _isLoadingModels
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.format_list_bulleted_rounded,
                          color: colorScheme.primary,
                        ),
                        tooltip: '获取并选择模型',
                        onPressed: _fetchAndSelectModel,
                      ),
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '放弃更改？',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        content: const Text(
          '你有未保存的更改，确定要放弃吗？',
          style: TextStyle(color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('继续编辑', style: TextStyle(color: Colors.grey[600])),
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
            child: const Text('放弃'),
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
      model: model.isEmpty ? 'deepseek-v4-flash' : model,
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
    context.pop();
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
