import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lumi/core/router/app_router.dart';
import 'package:lumi/core/theme/app_theme.dart';
import 'package:lumi/core/theme/theme_provider.dart';
import 'package:lumi/features/auth/presentation/providers/auth_provider.dart';
import 'package:toastification/toastification.dart';

class LumiApp extends ConsumerStatefulWidget {
  const LumiApp({super.key});

  @override
  ConsumerState<LumiApp> createState() => _LumiAppState();
}

class _LumiAppState extends ConsumerState<LumiApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(() => ref.read(authProvider).isLoggedIn);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    final theme = themeMode == AppThemeMode.romantic
        ? AppTheme.romantic
        : AppTheme.ocean;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isLoggedIn) {
        _router.go(AppRoutes.home);
      } else {
        _router.go(AppRoutes.login);
      }
    });

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
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }

    return ToastificationWrapper(
      child: MaterialApp.router(
        title: 'Lumi',
        theme: theme,
        routerConfig: _router,
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
