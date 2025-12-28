import 'package:flutter/material.dart';
import 'package:lumi/core/theme/app_theme.dart';
import 'package:lumi/features/lumi/presentation/pages/lumi_home_page.dart';

class LumiApp extends StatelessWidget {
  const LumiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumi',
      theme: AppTheme.romantic,
      home: const LumiHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
