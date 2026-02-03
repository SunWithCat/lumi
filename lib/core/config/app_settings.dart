import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumi/features/memory/data/database/app_database.dart';
import 'package:lumi/features/memory/presentation/providers/memory_provider.dart';

/// 画质等级
enum RenderQuality {
  low(512, '省电模式', '512x512'),
  medium(1024, '平衡模式', '1024x1024'),
  high(2048, '高清模式', '2048x2048');

  final int resolution;
  final String label;
  final String description;

  const RenderQuality(this.resolution, this.label, this.description);
}

class ApiSettings {
  final String baseUrl;
  final String apiKey;
  final String model;

  const ApiSettings({
    this.baseUrl = 'https://api.deepseek.com/v1',
    this.apiKey = '',
    this.model = 'deepseek-chat',
  });

  bool get isConfigured => apiKey.isNotEmpty;

  ApiSettings copyWith({String? baseUrl, String? apiKey, String? model}) {
    return ApiSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }
}

/// LLM 参数配置
class LLMSettings {
  final double temperature; // 0.0-2.0, 越高越随机
  final int maxTokens; // 最大输出 token 数
  final double topP; // 0.0-1.0, nucleus sampling

  const LLMSettings({
    this.temperature = 0.7,
    this.maxTokens = 500,
    this.topP = 1.0,
  });

  LLMSettings copyWith({double? temperature, int? maxTokens, double? topP}) {
    return LLMSettings(
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      topP: topP ?? this.topP,
    );
  }
}

/// 应用设置状态
class AppSettingsState {
  final RenderQuality renderQuality;
  final LLMSettings llmSettings;
  final ApiSettings apiSettings;

  const AppSettingsState({
    this.renderQuality = RenderQuality.medium,
    this.llmSettings = const LLMSettings(),
    this.apiSettings = const ApiSettings(),
  });

  AppSettingsState copyWith({
    RenderQuality? renderQuality,
    LLMSettings? llmSettings,
    ApiSettings? apiSettings,
  }) {
    return AppSettingsState(
      renderQuality: renderQuality ?? this.renderQuality,
      llmSettings: llmSettings ?? this.llmSettings,
      apiSettings: apiSettings ?? this.apiSettings,
    );
  }
}

/// 设置管理器
class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  static const _keyRenderQuality = 'render_quality';
  static const _keyLLMTemperature = 'llm_temperature';
  static const _keyLLMMaxTokens = 'llm_max_tokens';
  static const _keyLLMTopP = 'llm_top_p';
  static const _keyApiBaseUrl = 'api_base_url';
  static const _keyApiKey = 'api_key';
  static const _keyApiModel = 'api_model';

  final AppDatabase _db;
  late final Future<void> _loadFuture;

  AppSettingsNotifier(this._db) : super(const AppSettingsState()) {
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final qualityStr = await _db.getSetting(_keyRenderQuality);
    final tempStr = await _db.getSetting(_keyLLMTemperature);
    final maxTokensStr = await _db.getSetting(_keyLLMMaxTokens);
    final topPStr = await _db.getSetting(_keyLLMTopP);
    final baseUrlStr = await _db.getSetting(_keyApiBaseUrl);
    final apiKeyStr = await _db.getSetting(_keyApiKey);
    final modelStr = await _db.getSetting(_keyApiModel);

    RenderQuality quality = RenderQuality.medium;
    if (qualityStr != null) {
      final qualityIndex = int.tryParse(qualityStr) ?? 1;
      quality = RenderQuality.values[qualityIndex.clamp(0, 2)];
    }

    final llmSettings = LLMSettings(
      temperature: double.tryParse(tempStr ?? '') ?? 0.7,
      maxTokens: int.tryParse(maxTokensStr ?? '') ?? 500,
      topP: double.tryParse(topPStr ?? '') ?? 1.0,
    );

    final apiSettings = ApiSettings(
      baseUrl: baseUrlStr ?? 'https://api.deepseek.com/v1',
      apiKey: apiKeyStr ?? '',
      model: modelStr ?? 'deepseek-chat',
    );

    state = AppSettingsState(
      renderQuality: quality,
      llmSettings: llmSettings,
      apiSettings: apiSettings,
    );
  }

  /// 等待设置加载完成并返回当前状态
  Future<AppSettingsState> waitForLoad() async {
    await _loadFuture;
    return state;
  }

  Future<void> setRenderQuality(RenderQuality quality) async {
    state = state.copyWith(renderQuality: quality);
    await _db.setSetting(_keyRenderQuality, quality.index.toString());
  }

  /// 设置 LLM Temperature
  Future<void> setLLMTemperature(double value) async {
    final clamped = value.clamp(0.0, 2.0);
    state = state.copyWith(
      llmSettings: state.llmSettings.copyWith(temperature: clamped),
    );
    await _db.setSetting(_keyLLMTemperature, clamped.toString());
  }

  /// 设置 LLM Max Tokens
  Future<void> setLLMMaxTokens(int value) async {
    final clamped = value.clamp(100, 4096);
    state = state.copyWith(
      llmSettings: state.llmSettings.copyWith(maxTokens: clamped),
    );
    await _db.setSetting(_keyLLMMaxTokens, clamped.toString());
  }

  /// 设置 LLM Top P
  Future<void> setLLMTopP(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    state = state.copyWith(
      llmSettings: state.llmSettings.copyWith(topP: clamped),
    );
    await _db.setSetting(_keyLLMTopP, clamped.toString());
  }

  /// 批量更新 LLM 设置
  Future<void> updateLLMSettings(LLMSettings settings) async {
    state = state.copyWith(llmSettings: settings);
    await _db.setSetting(_keyLLMTemperature, settings.temperature.toString());
    await _db.setSetting(_keyLLMMaxTokens, settings.maxTokens.toString());
    await _db.setSetting(_keyLLMTopP, settings.topP.toString());
  }

  // 批量更新 API 设置
  Future<void> updateApiSettings(ApiSettings settings) async {
    state = state.copyWith(apiSettings: settings);
    await _db.setSetting(_keyApiBaseUrl, settings.baseUrl);
    await _db.setSetting(_keyApiKey, settings.apiKey);
    await _db.setSetting(_keyApiModel, settings.model);
  }

  Future<void> setApiBaseUrl(String baseUrl) async {
    state = state.copyWith(
      apiSettings: state.apiSettings.copyWith(baseUrl: baseUrl),
    );
    await _db.setSetting(_keyApiBaseUrl, baseUrl);
  }

  Future<void> setApiKey(String apiKey) async {
    state = state.copyWith(
      apiSettings: state.apiSettings.copyWith(apiKey: apiKey),
    );
    await _db.setSetting(_keyApiKey, apiKey);
  }

  Future<void> setApiModel(String model) async {
    state = state.copyWith(
      apiSettings: state.apiSettings.copyWith(model: model),
    );
    await _db.setSetting(_keyApiModel, model);
  }
}

/// Provider
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
      final db = ref.watch(databaseProvider);
      return AppSettingsNotifier(db);
    });
