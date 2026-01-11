import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumi/core/theme/app_theme.dart';
import 'package:lumi/features/memory/data/database/app_database.dart';
import 'package:lumi/features/memory/presentation/providers/memory_provider.dart';

enum AppThemeMode { romantic, ocean }

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  static const _keyTheme = 'app_theme';

  final AppDatabase _db;
  late final Future<void> _loadFuture;

  ThemeNotifier(this._db) : super(AppThemeMode.romantic) {
    _loadFuture = _load();
  }

  Future<void> _load() async {
    final themeStr = await _db.getSetting(_keyTheme);
    if (themeStr != null) {
      final themeIndex = int.tryParse(themeStr) ?? 0;
      state = AppThemeMode
          .values[themeIndex.clamp(0, AppThemeMode.values.length - 1)];
    }
  }

  /// 等待主题加载完成
  Future<AppThemeMode> waitForLoad() async {
    await _loadFuture;
    return state;
  }

  /// 设置主题并持久化
  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    await _db.setSetting(_keyTheme, mode.index.toString());
  }

  ThemeData get currentTheme {
    switch (state) {
      case AppThemeMode.romantic:
        return AppTheme.romantic;
      case AppThemeMode.ocean:
        return AppTheme.ocean;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  final db = ref.watch(databaseProvider);
  return ThemeNotifier(db);
});
