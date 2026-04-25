import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lumi/core/router/app_router.dart';
import 'package:lumi/core/theme/app_theme.dart';
import 'package:lumi/core/theme/theme_provider.dart';
import 'package:lumi/features/auth/presentation/providers/auth_provider.dart';
import 'package:toastification/toastification.dart';

class LumiApp extends ConsumerWidget {
  const LumiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    final theme = themeMode == AppThemeMode.romantic
        ? AppTheme.romantic
        : AppTheme.ocean;

    if (authState.isLoading) {
      return ToastificationWrapper(
        child: MaterialApp(
          title: 'Lumi',
          theme: theme,
          debugShowCheckedModeBanner: false,
          locale: const Locale('zh', 'CN'),
          supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            ),
          ),
        ),
      );
    }

    return ToastificationWrapper(
      child: MaterialApp.router(
        title: 'Lumi',
        theme: theme,
        routerConfig: createAppRouter(authState),
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh', 'CN'), // 中文本地化
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
