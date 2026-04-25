import 'package:go_router/go_router.dart';
import 'package:lumi/features/auth/presentation/providers/auth_provider.dart';
import 'package:lumi/features/auth/presentation/pages/login_page.dart';
import 'package:lumi/features/auth/presentation/pages/register_page.dart';
import 'package:lumi/features/lumi/presentation/pages/lumi_home_page.dart';
import 'package:lumi/features/memory/presentation/pages/memory_management_page.dart';
import 'package:lumi/features/settings/presentation/pages/api_settings_page.dart';
import 'package:lumi/features/settings/presentation/pages/llm_settings_page.dart';
import 'package:lumi/features/settings/presentation/pages/settings_page.dart';
import 'package:lumi/features/soul/presentation/pages/persona_settings_page.dart';

abstract class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const register = '/register';
  static const settings = '/settings';
  static const settingsPersona = '/settings/persona';
  static const settingsLlm = '/settings/llm';
  static const settingsApi = '/settings/api';
  static const settingsMemory = '/settings/memory';
}

GoRouter createAppRouter(AuthState authState) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    observers: [LumiHomePage.routeObserver],
    redirect: (context, state) {
      final goingToAuth =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (!authState.isLoggedIn && !goingToAuth) {
        return AppRoutes.login;
      }

      if (authState.isLoggedIn && goingToAuth) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const LumiHomePage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.settingsPersona,
        builder: (context, state) => const PersonaSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.settingsLlm,
        builder: (context, state) => const LLMSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.settingsApi,
        builder: (context, state) => const ApiSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.settingsMemory,
        builder: (context, state) => const MemoryManagementPage(),
      ),
    ],
  );
}
