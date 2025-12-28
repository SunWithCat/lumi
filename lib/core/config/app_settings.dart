import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waifu/features/memory/data/database/app_database.dart';
import 'package:waifu/features/soul/presentation/providers/persona_provider.dart';

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

/// 应用设置状态
class AppSettingsState {
  final RenderQuality renderQuality;

  const AppSettingsState({
    this.renderQuality = RenderQuality.medium,
  });

  AppSettingsState copyWith({RenderQuality? renderQuality}) {
    return AppSettingsState(
      renderQuality: renderQuality ?? this.renderQuality,
    );
  }
}

/// 设置管理器
class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  static const _keyRenderQuality = 'render_quality';
  final AppDatabase _db;

  AppSettingsNotifier(this._db) : super(const AppSettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final qualityStr = await _db.getSetting(_keyRenderQuality);
    if (qualityStr != null) {
      final qualityIndex = int.tryParse(qualityStr) ?? 1;
      state = AppSettingsState(
        renderQuality: RenderQuality.values[qualityIndex.clamp(0, 2)],
      );
    }
  }

  Future<void> setRenderQuality(RenderQuality quality) async {
    state = state.copyWith(renderQuality: quality);
    await _db.setSetting(_keyRenderQuality, quality.index.toString());
  }
}

/// Provider
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AppSettingsNotifier(db);
});
