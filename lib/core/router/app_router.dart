import 'package:go_router/go_router.dart';
import 'package:lumi/features/lumi/presentation/pages/lumi_home_page.dart';
import 'package:lumi/features/memory/presentation/pages/memory_management_page.dart';
import 'package:lumi/features/settings/presentation/pages/api_settings_page.dart';
import 'package:lumi/features/settings/presentation/pages/llm_settings_page.dart';
import 'package:lumi/features/settings/presentation/pages/settings_page.dart';
import 'package:lumi/features/soul/presentation/pages/persona_settings_page.dart';

abstract class AppRoutes {
  static const home = '/';
  static const settings = '/settings';
  static const settingsPersona = '/settings/persona';
  static const settingsLlm = '/settings/llm';
  static const settingsApi = '/settings/api';
  static const settingsMemory = '/settings/memory';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  observers: [LumiHomePage.routeObserver],
  routes: [
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
