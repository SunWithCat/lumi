import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lumi/core/theme/app_theme.dart';
import 'package:lumi/core/theme/theme_provider.dart';
import 'package:lumi/features/lumi/presentation/pages/lumi_home_page.dart';

class LumiApp extends ConsumerWidget {
  const LumiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final theme = themeMode == AppThemeMode.romantic
        ? AppTheme.romantic
        : AppTheme.ocean;
    return MaterialApp(
      title: 'Lumi',
      theme: theme,
      home: const LumiHomePage(),
      debugShowCheckedModeBanner: false,
      // 注册路由观察者，用于监听页面切换
      navigatorObservers: [LumiHomePage.routeObserver],
    );
  }
}
