import 'package:flutter/material.dart';
import 'package:waifu/core/theme/app_theme.dart';
import 'package:waifu/features/waifu/presentation/pages/waifu_home_page.dart';

class WaifuApp extends StatelessWidget {
  const WaifuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Waifu',
      theme: AppTheme.dark,
      home: const WaifuHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
